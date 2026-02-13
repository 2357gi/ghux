package ghq

import (
	"os/exec"
	"strings"
)

func Exists() bool {
	_, err := exec.LookPath("ghq")
	return err == nil
}

func Root() (string, error) {
	out, err := exec.Command("ghq", "root").Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(out)), nil
}

func List() ([]string, error) {
	out, err := exec.Command("ghq", "list").Output()
	if err != nil {
		return nil, err
	}
	lines := strings.Split(strings.TrimSpace(string(out)), "\n")
	var repos []string
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}
		repos = append(repos, line)
	}
	return repos, nil
}
