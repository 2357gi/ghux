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
		Stdin:     &escAbortReader{r: os.Stdin},
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

// escAbortReader wraps stdin so that pressing the Esc key aborts the prompt.
//
// promptui relies on chzyer/readline, which treats Esc (0x1b) as the start of
// an escape sequence (arrow keys send "Esc [ A" etc.) and therefore swallows a
// lone Esc keypress. A terminal in raw mode delivers each escape sequence in a
// single read, so a standalone Esc arrives as a one-byte read of 0x1b while
// real sequences arrive as multi-byte reads. We translate only the former into
// Ctrl-C (0x03), which readline reports as ErrInterrupt -> ErrAborted.
type escAbortReader struct {
	r io.Reader
}

func (e *escAbortReader) Read(p []byte) (int, error) {
	n, err := e.r.Read(p)
	if n == 1 && p[0] == 0x1b {
		p[0] = 0x03
	}
	return n, err
}

// Close is a no-op; we must not close the shared os.Stdin file descriptor.
func (e *escAbortReader) Close() error {
	return nil
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
