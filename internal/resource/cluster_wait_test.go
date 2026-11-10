package resource

import (
	"context"
	"errors"
	"testing"
	"time"
)

func TestPollTask(t *testing.T) {
	t.Run("waits for success", func(t *testing.T) {
		statuses := []string{"Pending", "Running", "Succeed"}
		calls := 0
		err := pollTask(context.Background(), time.Microsecond, func() (string, string, error) { s := statuses[calls]; calls++; return s, "", nil })
		if err != nil || calls != 3 {
			t.Fatalf("calls=%d error=%v", calls, err)
		}
	})
	for _, status := range []string{"Failed", "Stopped", "Cancelled", "Deleted", "RebuildCanceled", "unrecognized"} {
		t.Run(status, func(t *testing.T) {
			if err := pollTask(context.Background(), time.Microsecond, func() (string, string, error) { return status, "operation did not finish", nil }); err == nil {
				t.Fatal("unsuccessful task accepted")
			}
		})
	}
	t.Run("cancelled", func(t *testing.T) {
		ctx, cancel := context.WithCancel(context.Background())
		err := pollTask(ctx, time.Hour, func() (string, string, error) { cancel(); return "Running", "", nil })
		if !errors.Is(err, context.Canceled) {
			t.Fatalf("error=%v", err)
		}
	})
	t.Run("read error", func(t *testing.T) {
		expected := errors.New("unavailable")
		err := pollTask(context.Background(), time.Microsecond, func() (string, string, error) { return "", "", expected })
		if !errors.Is(err, expected) {
			t.Fatalf("error=%v", err)
		}
	})
}
