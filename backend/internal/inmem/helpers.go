package inmem

import (
	"strings"

	"github.com/anuyatra/backend/internal/repository"
)

func paginate[T any](items []*T, p repository.Pagination) ([]*T, int) {
	total := len(items)
	if p.Offset >= total {
		return nil, total
	}
	end := p.Offset + p.Limit
	if end > total {
		end = total
	}
	return items[p.Offset:end], total
}

func containsFold(haystack, needle string) bool {
	return strings.Contains(strings.ToLower(haystack), strings.ToLower(needle))
}

func containsStr(list []string, val string) bool {
	for _, s := range list {
		if s == val {
			return true
		}
	}
	return false
}
