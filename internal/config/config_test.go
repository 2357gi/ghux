package config

import (
	"os"
	"path/filepath"
	"testing"
)

func TestExpandPath(t *testing.T) {
	t.Setenv("HOME", "/tmp/home")
	t.Setenv("X", "abc")

	got, err := ExpandPath("~/$X")
	if err != nil {
		t.Fatal(err)
	}
	want := filepath.Join("/tmp/home", "abc")
	if got != want {
		t.Fatalf("got %q want %q", got, want)
	}
}

func TestLoadWithEnvOverride(t *testing.T) {
	tmp := t.TempDir()
	cfgPath := filepath.Join(tmp, "config.toml")
	if err := os.WriteFile(cfgPath, []byte("recent_limit = 3\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	t.Setenv("GHUX_CONFIG", cfgPath)
	t.Setenv("GHUX_RECENT_LIMIT", "7")
	t.Setenv("HOME", "/tmp/home")

	cfg, err := Load()
	if err != nil {
		t.Fatal(err)
	}
	if cfg.RecentLimit != 7 {
		t.Fatalf("env override failed: %d", cfg.RecentLimit)
	}
}
