package model

import "fmt"

type ItemType string

const (
	TypeRepo    ItemType = "repo"
	TypeAlias   ItemType = "alias"
	TypeSession ItemType = "session"
	TypeWindow  ItemType = "window"
)

func (t ItemType) Valid() bool {
	switch t {
	case TypeRepo, TypeAlias, TypeSession, TypeWindow:
		return true
	default:
		return false
	}
}

type Pair struct {
	Key     string
	Display string
}

type Entry struct {
	Display string
	Type    ItemType
	Key     string
}

type AliasRecord struct {
	Alias string
	Name  string
	Dir   string
}

func FormatDisplay(t ItemType, body string) string {
	label := fmt.Sprintf("[%-7s]", string(t))
	return fmt.Sprintf("%s %s", colorizeLabel(t, label), body)
}

func colorizeLabel(t ItemType, label string) string {
	const reset = "\033[0m"
	code := ""
	switch t {
	case TypeSession:
		code = "\033[32m"
	case TypeWindow:
		code = "\033[36m"
	case TypeAlias:
		code = "\033[33m"
	case TypeRepo:
		code = "\033[34m"
	default:
		return label
	}
	return code + label + reset
}
