package user

import (
	"context"
	"encoding/json"
	"fmt"

	"sea-try-go/service/user/user/api/internal/types"
	"sea-try-go/service/user/user/rpc/pb"
)

func currentUserID(ctx context.Context) (int64, error) {
	userID, ok := ctx.Value("userId").(json.Number)
	if !ok {
		return 0, fmt.Errorf("ctx userId is not json.Number")
	}
	return userID.Int64()
}

func avatarHistoryItemFromPB(item *pb.AvatarHistoryItem) types.AvatarHistoryItem {
	if item == nil {
		return types.AvatarHistoryItem{}
	}

	return types.AvatarHistoryItem{
		Id:          item.Id,
		AvatarUrl:   item.AvatarUrl,
		ContentType: item.ContentType,
		SizeBytes:   item.SizeBytes,
		IsCurrent:   item.IsCurrent,
		CreateTime:  item.CreateTime,
	}
}
