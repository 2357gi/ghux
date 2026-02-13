package config

import (
	"errors"
	"os"
	"path/filepath"
	"strconv"

	"github.com/BurntSushi/toml"
)

const defaultRecentLimit = 10

type Config struct {
	AliasesPath    string
	RecentPath     string
	RecentLimit    int
	DotfilesOption bool
}

type fileConfig struct {
	AliasesPath    string `toml:"aliases_path"`
	RecentPath     string `toml:"recent_path"`
	RecentLimit    int    `toml:"recent_limit"`
	DotfilesOption bool   `toml:"dotfiles_option"`
}

func defaultValues() Config {
	home := os.Getenv("HOME")
	xdgCache := os.Getenv("XDG_CACHE_HOME")
	if xdgCache == "" {
		xdgCache = filepath.Join(home, ".cache")
	}
	return Config{
		AliasesPath: filepath.Join(home, ".ghux_aliases"),
		RecentPath:  filepath.Join(xdgCache, "ghux", "recent"),
		RecentLimit: defaultRecentLimit,
	}
}

func Load() (Config, error) {
	cfg := defaultValues()

	fp := os.Getenv("GHUX_CONFIG")
	if fp == "" {
		xdgConfig := os.Getenv("XDG_CONFIG_HOME")
		if xdgConfig == "" {
			xdgConfig = filepath.Join(os.Getenv("HOME"), ".config")
		}
		fp = filepath.Join(xdgConfig, "ghux", "config.toml")
	}
	if st, err := os.Stat(fp); err == nil && !st.IsDir() {
		var fc fileConfig
		if _, err := toml.DecodeFile(fp, &fc); err != nil {
			return cfg, err
		}
		applyFileConfig(&cfg, fc)
	}

	applyEnvConfig(&cfg)
	if err := normalize(&cfg); err != nil {
		return cfg, err
	}
	return cfg, nil
}

func applyFileConfig(cfg *Config, fc fileConfig) {
	if fc.AliasesPath != "" {
		cfg.AliasesPath = fc.AliasesPath
	}
	if fc.RecentPath != "" {
		cfg.RecentPath = fc.RecentPath
	}
	if fc.RecentLimit > 0 {
		cfg.RecentLimit = fc.RecentLimit
	}
	cfg.DotfilesOption = fc.DotfilesOption
}

func applyEnvConfig(cfg *Config) {
	if v := os.Getenv("GHUX_ALIASES_PATH"); v != "" {
		cfg.AliasesPath = v
	}
	if v := os.Getenv("GHUX_RECENT_PATH"); v != "" {
		cfg.RecentPath = v
	}
	if v := os.Getenv("GHUX_RECENT_LIMIT"); v != "" {
		if n, err := strconv.Atoi(v); err == nil && n > 0 {
			cfg.RecentLimit = n
		}
	}
	if v := os.Getenv("GHUX_DOTFILES_OPTION"); v != "" {
		cfg.DotfilesOption = (v == "1" || v == "true" || v == "TRUE")
	}
}

func normalize(cfg *Config) error {
	var err error
	cfg.AliasesPath, err = ExpandPath(cfg.AliasesPath)
	if err != nil {
		return err
	}
	cfg.RecentPath, err = ExpandPath(cfg.RecentPath)
	if err != nil {
		return err
	}
	if cfg.RecentLimit <= 0 {
		return errors.New("recent_limit must be > 0")
	}
	return nil
}

func ExpandPath(in string) (string, error) {
	if in == "" {
		return "", errors.New("empty path")
	}
	expanded := os.ExpandEnv(in)
	if expanded[0] == '~' {
		home := os.Getenv("HOME")
		if home == "" {
			return "", errors.New("HOME is not set")
		}
		if expanded == "~" {
			expanded = home
		} else if len(expanded) > 1 && expanded[1] == '/' {
			expanded = filepath.Join(home, expanded[2:])
		}
	}
	return expanded, nil
}
