package recent

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/2357gi/ghux/internal/model"
)

func TestRecordAndLoad(t *testing.T) {
	tmp := t.TempDir()
	path := filepath.Join(tmp, "recent")

	if err := Record(path, 3, model.TypeAlias, "dotfiles"); err != nil {
		t.Fatal(err)
	}
	if err := Record(path, 3, model.TypeRepo, "github.com/a/b"); err != nil {
		t.Fatal(err)
	}
	if err := Record(path, 3, model.TypeAlias, "dotfiles"); err != nil {
		t.Fatal(err)
	}
	st, err := Load(path)
	if err != nil {
		t.Fatal(err)
	}
	if st.LatestType != model.TypeAlias || st.LatestKey != "dotfiles" {
		t.Fatalf("unexpected latest: %s %s", st.LatestType, st.LatestKey)
	}
	if st.RankByMapKey["alias\tdotfiles"] != 1 {
		t.Fatalf("alias rank was not 1: %v", st.RankByMapKey)
	}
	if st.RankByMapKey["repo\tgithub.com/a/b"] != 2 {
		t.Fatalf("repo rank was not 2: %v", st.RankByMapKey)
	}
}

func TestSortEntriesByRecent(t *testing.T) {
	st := State{
		RankByMapKey: map[string]int{
			"alias\ta": 2,
			"repo\tr":  1,
		},
	}
	in := []model.Entry{
		{Display: "[alias] a", Type: model.TypeAlias, Key: "a"},
		{Display: "[repo] r", Type: model.TypeRepo, Key: "r"},
		{Display: "[session] s", Type: model.TypeSession, Key: "s"},
	}
	out := SortEntriesByRecent(st, in)
	if len(out) != 3 {
		t.Fatalf("unexpected length: %d", len(out))
	}
	if out[0].Type != model.TypeRepo || out[1].Type != model.TypeAlias || out[2].Type != model.TypeSession {
		t.Fatalf("unexpected order: %+v", out)
	}
}

func TestInitCreatesFile(t *testing.T) {
	tmp := t.TempDir()
	path := filepath.Join(tmp, "cache", "ghux", "recent")
	if err := Init(path); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(path); err != nil {
		t.Fatal(err)
	}
}
