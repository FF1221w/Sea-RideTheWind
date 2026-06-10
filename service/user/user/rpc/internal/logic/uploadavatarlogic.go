package logic

import (
	"context"
	"fmt"

	"sea-try-go/service/common/logger"
	"sea-try-go/service/common/snowflake"
	"sea-try-go/service/user/common/errmsg"
	"sea-try-go/service/user/user/rpc/internal/model"
	"sea-try-go/service/user/user/rpc/internal/svc"
	"sea-try-go/service/user/user/rpc/pb"

	"github.com/zeromicro/go-zero/core/logx"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type UploadAvatarLogic struct {
	ctx    context.Context
	svcCtx *svc.ServiceContext
	logx.Logger
}

func NewUploadAvatarLogic(ctx context.Context, svcCtx *svc.ServiceContext) *UploadAvatarLogic {
	return &UploadAvatarLogic{
		ctx:    ctx,
		svcCtx: svcCtx,
		Logger: logx.WithContext(ctx),
	}
}

func (l *UploadAvatarLogic) UploadAvatar(in *pb.UploadAvatarReq) (*pb.UploadAvatarResp, error) {
	avatarURL := normalizedAvatarURL(in.AvatarUrl)
	if avatarURL == "" {
		return nil, status.Error(codes.InvalidArgument, "avatar_url is required")
	}

	historySnowflakeID, err := snowflake.GetID()
	if err != nil {
		logger.LogBusinessErr(l.ctx, errmsg.ErrorSnowflakeID, err)
		return nil, status.Error(codes.Internal, "history_id鐢熸垚澶辫触")
	}

	history, _, err := l.svcCtx.UserModel.CreateAvatarHistory(
		l.ctx,
		in.Uid,
		fmt.Sprintf("%d", historySnowflakeID),
		avatarURL,
		model.NormalizeAvatarContentType(in.ContentType),
		in.SizeBytes,
	)
	if err != nil {
		switch err {
		case model.ErrorNotFound:
			logger.LogBusinessErr(l.ctx, errmsg.ErrorUserNotExist, err)
			return nil, status.Error(codes.NotFound, "鐢ㄦ埛涓嶅瓨鍦?")
		default:
			logger.LogBusinessErr(l.ctx, errmsg.ErrorDbInsert, err)
			return nil, status.Error(codes.Internal, "DB鎻掑叆澶辫触")
		}
	}

	return &pb.UploadAvatarResp{
		AvatarUrl: avatarURL,
		History:   avatarHistoryItemFromModel(history),
	}, nil
}
