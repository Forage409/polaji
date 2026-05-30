INSERT OR IGNORE INTO templates (id, title, description, cover_image, category, author_id, author_name, status, form_config_raw, result_config_raw) VALUES 
('group_judge', '群聊判官', '朋友局临时法庭，看看今天谁负责请奶茶。', 'cover_judge', 'funny', 'system_admin', '整活局官方', 'published', '{}', '{}'),
('friend_vote', '好友投票', '朋友局临时排行榜，看看大家心里的TOP1是谁。', 'cover_vote', 'interactive', 'system_admin', '整活局官方', 'published', '{}', '{}'),
('persona_card', '今日人设', '一键生成你今天的社交名片与精神状态。', 'cover_persona', 'social', 'system_admin', '整活局官方', 'published', '{}', '{}'),
('truth_dare', '真心话大冒险', '经典游戏，朋友局必备破冰神器。', 'cover_truth_dare', 'game', 'system_admin', '整活局官方', 'published', '{}', '{}'),
('rich_card', '低调富豪鉴定', '一键测试你隐藏的财力与消费习惯。', 'cover_rich', 'funny', 'system_admin', '整活局官方', 'published', '{}', '{}'),
('single_card', '脱单潜力测试', '测测你最近的桃花运和脱单可能性。', 'cover_single', 'social', 'system_admin', '整活局官方', 'published', '{}', '{}'),
('stay_up', '熬夜等级鉴定', '看看你是哪个级别的修仙党。', 'cover_stay_up', 'funny', 'system_admin', '整活局官方', 'published', '{}', '{}'),
('boss_card', '老板气质检测', '一句话证明你有当老板的潜质。', 'cover_boss', 'funny', 'system_admin', '整活局官方', 'published', '{}', '{}');

INSERT OR IGNORE INTO template_stats (template_id, view_count, start_count, generate_count, usage_count, share_count, like_count, report_count) VALUES 
('group_judge', 1234, 100, 50, 50, 12, 45, 0),
('friend_vote', 2144, 200, 90, 90, 24, 88, 0),
('persona_card', 3412, 400, 120, 120, 55, 120, 0),
('truth_dare', 890, 50, 20, 20, 5, 30, 0),
('rich_card', 500, 40, 10, 10, 2, 10, 0),
('single_card', 600, 45, 15, 15, 3, 20, 0),
('stay_up', 400, 30, 5, 5, 1, 5, 0),
('boss_card', 300, 20, 4, 4, 1, 3, 0);
