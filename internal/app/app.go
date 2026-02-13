package app

import (
	"errors"
	"fmt"
	"path/filepath"
	"strings"

	"github.com/2357gi/ghux/internal/aliasstore"
	"github.com/2357gi/ghux/internal/config"
	"github.com/2357gi/ghux/internal/ghq"
	"github.com/2357gi/ghux/internal/model"
	"github.com/2357gi/ghux/internal/recent"
	"github.com/2357gi/ghux/internal/tmux"
	"github.com/2357gi/ghux/internal/ui"
)

func Run(args []string) error {
	if !tmux.Exists() {
		return errors.New("tmux not found in PATH")
	}

	cfg, err := config.Load()
	if err != nil {
		return fmt.Errorf("load config: %w", err)
	}
	if err := aliasstore.EnsureFile(cfg.AliasesPath); err != nil {
		return fmt.Errorf("ensure alias file: %w", err)
	}
	if err := recent.Init(cfg.RecentPath); err != nil {
		return fmt.Errorf("init recent: %w", err)
	}

	aliases, aliasPairs, err := aliasstore.Load(cfg.AliasesPath)
	if err != nil {
		return fmt.Errorf("load aliases: %w", err)
	}

	var projectName, projectDir string
	if len(args) > 0 && args[0] != "" {
		if a, ok := aliases[args[0]]; ok {
			projectName, projectDir = a.Name, a.Dir
			_ = recent.Record(cfg.RecentPath, cfg.RecentLimit, model.TypeAlias, a.Alias)
		}
	}

	if projectName == "" || projectDir == "" {
		entry, err := selectEntry(cfg, aliasPairs)
		if err != nil {
			return err
		}
		switch entry.Type {
		case model.TypeSession:
			_ = recent.Record(cfg.RecentPath, cfg.RecentLimit, model.TypeSession, entry.Key)
			if tmux.InTmux() {
				return tmux.SwitchClient(entry.Key)
			}
			return tmux.AttachSession(entry.Key)
		case model.TypeWindow:
			_ = recent.Record(cfg.RecentPath, cfg.RecentLimit, model.TypeWindow, entry.Key)
			sess, _, err := tmux.ResolveWindowTarget(entry.Key)
			if err != nil {
				return err
			}
			if tmux.InTmux() {
				if err := tmux.SwitchClient(sess); err != nil {
					return err
				}
				return tmux.SelectWindow(entry.Key)
			}
			if err := tmux.AttachSession(sess); err != nil {
				return err
			}
			return tmux.SelectWindow(entry.Key)
		case model.TypeAlias:
			a, ok := aliases[entry.Key]
			if !ok {
				return errors.New("selected alias not found")
			}
			projectName, projectDir = a.Name, a.Dir
			_ = recent.Record(cfg.RecentPath, cfg.RecentLimit, model.TypeAlias, a.Alias)
		case model.TypeRepo:
			root, err := ghq.Root()
			if err != nil {
				return fmt.Errorf("ghq root failed: %w", err)
			}
			projectDir = filepath.Join(root, entry.Key)
			projectName = sanitizeSessionName(filepath.Base(entry.Key))
			_ = recent.Record(cfg.RecentPath, cfg.RecentLimit, model.TypeRepo, entry.Key)
		default:
			return errors.New("unsupported selection type")
		}
	}

	projectDir, err = config.ExpandPath(projectDir)
	if err != nil {
		return fmt.Errorf("expand project dir: %w", err)
	}
	if projectName == "" || projectDir == "" {
		return errors.New("failed to resolve target project")
	}

	if !tmux.HasSession(projectName) {
		if err := tmux.NewDetachedSession(projectName, projectDir); err != nil {
			return fmt.Errorf("create session: %w", err)
		}
	}

	if tmux.InTmux() {
		return tmux.SwitchClient(projectName)
	}
	return tmux.AttachSession(projectName)
}

func selectEntry(cfg config.Config, aliasPairs []model.Pair) (model.Entry, error) {
	st, err := recent.Load(cfg.RecentPath)
	if err != nil {
		return model.Entry{}, err
	}

	sessionPairs, _ := tmux.ListSessionsExcludingCurrent()
	windowPairs, _ := tmux.ListWindowsExcludingCurrent()

	sessionPairs = recent.FilterExcludingLatest(st, model.TypeSession, sessionPairs)
	windowPairs = recent.FilterExcludingLatest(st, model.TypeWindow, windowPairs)
	aliasPairs = recent.FilterExcludingLatest(st, model.TypeAlias, aliasPairs)

	var entries []model.Entry
	entries = append(entries, toEntries(model.TypeSession, sessionPairs)...)
	entries = append(entries, toEntries(model.TypeWindow, windowPairs)...)
	entries = append(entries, toEntries(model.TypeAlias, aliasPairs)...)

	if ghq.Exists() {
		repos, err := ghq.List()
		if err == nil {
			var repoPairs []model.Pair
			for _, r := range repos {
				repoPairs = append(repoPairs, model.Pair{Key: r, Display: model.FormatDisplay(model.TypeRepo, r)})
			}
			repoPairs = recent.FilterExcludingLatest(st, model.TypeRepo, repoPairs)
			entries = append(entries, toEntries(model.TypeRepo, repoPairs)...)
		}
	}

	entries = recent.SortEntriesByRecent(st, entries)
	if len(entries) == 0 {
		return model.Entry{}, errors.New("no selectable entries")
	}
	e, err := ui.SelectEntry(entries)
	if err != nil {
		if errors.Is(err, ui.ErrAborted) {
			return model.Entry{}, errors.New("selection cancelled")
		}
		return model.Entry{}, err
	}
	return e, nil
}

func toEntries(t model.ItemType, pairs []model.Pair) []model.Entry {
	out := make([]model.Entry, 0, len(pairs))
	for _, p := range pairs {
		if p.Key == "" || p.Display == "" {
			continue
		}
		out = append(out, model.Entry{
			Display: p.Display,
			Type:    t,
			Key:     p.Key,
		})
	}
	return out
}

func sanitizeSessionName(name string) string {
	return strings.Replace(name, ".", "", 1)
}
