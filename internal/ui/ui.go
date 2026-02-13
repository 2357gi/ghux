package ui

import (
	"errors"
	"io"
	"os"
	"strings"

	"github.com/2357gi/ghux/internal/model"
	"github.com/manifoldco/promptui"
)

var ErrAborted = errors.New("selection aborted")

func SelectEntry(entries []model.Entry) (model.Entry, error) {
	templates := &promptui.SelectTemplates{
		Label:    "{{ . }}",
		Active:   "▸ {{ .Display }}",
		Inactive: "  {{ .Display }}",
		Selected: "{{ .Display }}",
	}
	p := promptui.Select{
		Label:     "ghux",
		Items:     entries,
		Templates: templates,
		Size:      20,
		Stdout:    &bellFilterWriter{w: os.Stdout},
		Searcher: func(input string, index int) bool {
			e := entries[index]
			candidate := strings.ToLower(e.Display + "\t" + string(e.Type) + "\t" + e.Key)
			return strings.Contains(candidate, strings.ToLower(input))
		},
		StartInSearchMode: true,
	}
	i, _, err := p.Run()
	if err != nil {
		return model.Entry{}, ErrAborted
	}
	return entries[i], nil
}

type bellFilterWriter struct {
	w io.Writer
}

func (b *bellFilterWriter) Write(p []byte) (int, error) {
	filtered := make([]byte, 0, len(p))
	for _, c := range p {
		if c == '\a' {
			continue
		}
		filtered = append(filtered, c)
	}
	_, err := b.w.Write(filtered)
	if err != nil {
		return 0, err
	}
	return len(p), nil
}

func (b *bellFilterWriter) Close() error {
	return nil
}
