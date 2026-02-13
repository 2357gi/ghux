package aliasstore

import (
	"bufio"
	"os"
	"strings"

	"github.com/2357gi/ghux/internal/model"
)

func EnsureFile(path string) error {
	if err := os.MkdirAll(dir(path), 0o755); err != nil {
		return err
	}
	f, err := os.OpenFile(path, os.O_CREATE, 0o644)
	if err != nil {
		return err
	}
	return f.Close()
}

func Load(path string) (map[string]model.AliasRecord, []model.Pair, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, nil, err
	}
	defer file.Close()

	m := map[string]model.AliasRecord{}
	var pairs []model.Pair
	sc := bufio.NewScanner(file)
	for sc.Scan() {
		line := strings.TrimSpace(sc.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		parts := strings.SplitN(line, ",", 3)
		if len(parts) < 3 {
			continue
		}
		alias := strings.TrimSpace(parts[0])
		name := strings.TrimSpace(parts[1])
		dirp := strings.TrimSpace(parts[2])
		if alias == "" || name == "" || dirp == "" {
			continue
		}
		rec := model.AliasRecord{Alias: alias, Name: sanitizeSessionName(name), Dir: dirp}
		m[alias] = rec
		pairs = append(pairs, model.Pair{Key: alias, Display: model.FormatDisplay(model.TypeAlias, alias)})
	}
	if err := sc.Err(); err != nil {
		return nil, nil, err
	}
	return m, pairs, nil
}

func sanitizeSessionName(name string) string {
	return strings.Replace(name, ".", "", 1)
}

func dir(path string) string {
	for i := len(path) - 1; i >= 0; i-- {
		if path[i] == '/' {
			if i == 0 {
				return "/"
			}
			return path[:i]
		}
	}
	return "."
}
