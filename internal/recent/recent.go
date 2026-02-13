package recent

import (
	"bufio"
	"os"
	"path/filepath"
	"strings"

	"github.com/2357gi/ghux/internal/model"
)

type State struct {
	RankByMapKey map[string]int
	LatestType   model.ItemType
	LatestKey    string
}

func Init(path string) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	f, err := os.OpenFile(path, os.O_CREATE, 0o644)
	if err != nil {
		return err
	}
	return f.Close()
}

func Load(path string) (State, error) {
	st := State{RankByMapKey: map[string]int{}}
	file, err := os.Open(path)
	if err != nil {
		if os.IsNotExist(err) {
			return st, nil
		}
		return st, err
	}
	defer file.Close()

	sc := bufio.NewScanner(file)
	rank := 1
	for sc.Scan() {
		t, k, ok := parseLine(sc.Text())
		if !ok {
			continue
		}
		if st.LatestKey == "" {
			st.LatestType = t
			st.LatestKey = k
		}
		mapKey := string(t) + "\t" + k
		if _, exists := st.RankByMapKey[mapKey]; exists {
			continue
		}
		st.RankByMapKey[mapKey] = rank
		rank++
	}
	if err := sc.Err(); err != nil {
		return st, err
	}
	return st, nil
}

func FilterExcludingLatest(st State, t model.ItemType, in []model.Pair) []model.Pair {
	if st.LatestType != t || st.LatestKey == "" {
		return in
	}
	out := make([]model.Pair, 0, len(in))
	for _, p := range in {
		if p.Key == st.LatestKey {
			continue
		}
		out = append(out, p)
	}
	return out
}

func SortEntriesByRecent(st State, in []model.Entry) []model.Entry {
	type ranked struct {
		Entry model.Entry
		Rank  int
		Index int
	}
	var pri []ranked
	var rest []model.Entry
	for i, e := range in {
		mk := string(e.Type) + "\t" + e.Key
		if rank, ok := st.RankByMapKey[mk]; ok {
			pri = append(pri, ranked{Entry: e, Rank: rank, Index: i})
			continue
		}
		rest = append(rest, e)
	}
	for i := 0; i < len(pri)-1; i++ {
		for j := i + 1; j < len(pri); j++ {
			if pri[j].Rank < pri[i].Rank || (pri[j].Rank == pri[i].Rank && pri[j].Index < pri[i].Index) {
				pri[i], pri[j] = pri[j], pri[i]
			}
		}
	}
	out := make([]model.Entry, 0, len(in))
	for _, p := range pri {
		out = append(out, p.Entry)
	}
	out = append(out, rest...)
	return out
}

func Record(path string, limit int, t model.ItemType, key string) error {
	if !t.Valid() || key == "" {
		return nil
	}
	if err := Init(path); err != nil {
		return err
	}

	var existing []string
	if b, err := os.ReadFile(path); err == nil {
		lines := strings.Split(string(b), "\n")
		for _, line := range lines {
			line = strings.TrimSpace(line)
			if line == "" {
				continue
			}
			tt, kk, ok := parseLine(line)
			if !ok {
				continue
			}
			if tt == t && kk == key {
				continue
			}
			existing = append(existing, string(tt)+"\t"+kk)
		}
	}

	lines := make([]string, 0, limit)
	lines = append(lines, string(t)+"\t"+key)
	for _, line := range existing {
		if len(lines) >= limit {
			break
		}
		lines = append(lines, line)
	}
	content := strings.Join(lines, "\n")
	if content != "" {
		content += "\n"
	}
	return os.WriteFile(path, []byte(content), 0o644)
}

func parseLine(line string) (model.ItemType, string, bool) {
	parts := strings.SplitN(line, "\t", 2)
	if len(parts) < 2 {
		return "", "", false
	}
	t := model.ItemType(parts[0])
	k := parts[1]
	if !t.Valid() || k == "" {
		return "", "", false
	}
	return t, k, true
}
