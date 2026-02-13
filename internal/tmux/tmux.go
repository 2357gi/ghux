package tmux

import (
	"errors"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/2357gi/ghux/internal/model"
)

func Exists() bool {
	_, err := exec.LookPath("tmux")
	return err == nil
}

func InTmux() bool {
	return os.Getenv("TMUX") != ""
}

func ListSessionsExcludingCurrent() ([]model.Pair, error) {
	if !InTmux() {
		return nil, nil
	}
	current, _ := output("tmux", "display-message", "-p", "#S")
	sessionNamesRaw, err := output("tmux", "list-sessions", "-F", "#S")
	if err != nil {
		return nil, nil
	}
	current = strings.TrimSpace(current)
	var out []model.Pair
	for _, sess := range splitLines(sessionNamesRaw) {
		if sess == "" || sess == current {
			continue
		}
		out = append(out, model.Pair{Key: sess, Display: model.FormatDisplay(model.TypeSession, sess)})
	}
	return out, nil
}

func ListWindowsExcludingCurrent() ([]model.Pair, error) {
	if !InTmux() {
		return nil, nil
	}
	current, _ := output("tmux", "display-message", "-p", "#S:#I")
	raw, err := output("tmux", "list-windows", "-a", "-F", "#{session_name}\t#{window_index}\t#{pane_current_path}\t#{window_name}")
	if err != nil {
		return nil, nil
	}
	current = strings.TrimSpace(current)
	var out []model.Pair
	for _, line := range splitLines(raw) {
		parts := strings.SplitN(line, "\t", 4)
		if len(parts) < 4 {
			continue
		}
		sess := parts[0]
		idx := parts[1]
		panePath := parts[2]
		winName := parts[3]
		if sess == "" || idx == "" {
			continue
		}
		key := sess + ":" + idx
		if key == current {
			continue
		}
		title := branchName(panePath)
		if title == "" {
			title = winName
		}
		out = append(out, model.Pair{
			Key:     key,
			Display: model.FormatDisplay(model.TypeWindow, key+": "+title),
		})
	}
	return out, nil
}

func HasSession(name string) bool {
	err := exec.Command("tmux", "has-session", "-t", name).Run()
	return err == nil
}

func NewDetachedSession(name, dir string) error {
	cmd := exec.Command("tmux", "new-session", "-ds", name)
	cmd.Dir = dir
	cmd.Env = withoutTMUX(os.Environ())
	return cmd.Run()
}

func SwitchClient(target string) error {
	return exec.Command("tmux", "switch-client", "-t", target).Run()
}

func AttachSession(target string) error {
	return exec.Command("tmux", "attach-session", "-t", target).Run()
}

func SelectWindow(target string) error {
	return exec.Command("tmux", "select-window", "-t", target).Run()
}

func branchName(p string) string {
	if p == "" {
		return ""
	}
	gitPath := filepath.Join(p, ".git")
	if st, err := os.Stat(gitPath); err == nil && st.IsDir() {
		if head, err := os.ReadFile(filepath.Join(gitPath, "HEAD")); err == nil {
			return parseHead(string(head))
		}
	}
	if b, err := os.ReadFile(gitPath); err == nil {
		line := strings.TrimSpace(string(b))
		line = strings.TrimPrefix(line, "gitdir: ")
		headPath := filepath.Join(line, "HEAD")
		if head, err := os.ReadFile(headPath); err == nil {
			return parseHead(string(head))
		}
	}
	return ""
}

func parseHead(head string) string {
	head = strings.TrimSpace(head)
	const pfx = "ref: refs/heads/"
	if strings.HasPrefix(head, pfx) {
		return strings.TrimPrefix(head, pfx)
	}
	return ""
}

func output(name string, args ...string) (string, error) {
	out, err := exec.Command(name, args...).Output()
	if err != nil {
		return "", err
	}
	return string(out), nil
}

func splitLines(s string) []string {
	s = strings.TrimSpace(s)
	if s == "" {
		return nil
	}
	return strings.Split(s, "\n")
}

func ResolveWindowTarget(target string) (session string, window string, err error) {
	parts := strings.SplitN(target, ":", 2)
	if len(parts) != 2 || parts[0] == "" || parts[1] == "" {
		return "", "", errors.New("invalid window target")
	}
	return parts[0], parts[1], nil
}

func withoutTMUX(env []string) []string {
	out := make([]string, 0, len(env))
	for _, e := range env {
		if strings.HasPrefix(e, "TMUX=") {
			continue
		}
		out = append(out, e)
	}
	return out
}
