const string = @import("utils/string.zig").string;

const Message = @This();

message_id: u64,
from: ?UserObject = null,
sender_chat: ?ChatObject = null,
date: u64,
chat: ChatObject,
forward_from: ?UserObject = null,
forward_from_chat: ?ChatObject = null,
forward_from_message_id: ?u64 = null,
// reply_to_message: ?MessageObject = null,
has_protected_content: ?bool = null,
text: ?[]const u8 = null,
audio: ?AudioObject = null,
document: ?DocumentObject = null,

pub fn chatId(message: *const Message) u64 {
    return message.chat.id;
}

pub fn isCommand(message: *const Message) bool {
    if (message.text) |text| {
        return text.len > 0 and text[0] == '/';
    }
    return false;
}

pub fn command(message: *const Message) ?string {
    return message.text;
}

const ChatObject = struct {
    id: u64,
    type: []const u8,
    title: ?[]const u8 = null,
    username: ?[]const u8 = null,
    first_name: ?[]const u8 = null,
    last_name: ?[]const u8 = null,
    is_forum: ?bool = null,
    // photo	ChatPhoto	Optional. Chat photo. Returned only in getChat.
    // active_usernames: ?[][]const u8 = null,
    emoji_status_custom_emoji_id: ?[]const u8 = null,
    emoji_status_expiration_date: ?u64 = null,
    bio: ?[]const u8 = null,
    has_private_forwards: ?bool = null,
    has_restricted_voice_and_video_messages: ?bool = null,
    join_to_send_messages: ?bool = null,
    join_by_request: ?bool = null,
    description: ?[]const u8 = null,
    invite_link: ?[]const u8 = null,
    // pinned_message: ?MessageObject = null,
    // permissions	ChatPermissions	Optional. Default chat member permissions, for groups and supergroups. Returned only in getChat.
    slow_mode_delay: ?u64 = null,
    message_auto_delete_time: ?u64 = null,
    has_aggressive_anti_spam_enabled: ?bool = null,
    has_hidden_members: ?bool = null,
    has_protected_content: ?bool = null,
    sticker_set_name: ?[]const u8 = null,
    can_set_sticker_set: ?[]const u8 = null,
    linked_chat_id: ?u64 = null,
};

const UserObject = struct {
    id: u64,
    is_bot: bool,
    first_name: []const u8,
    last_name: ?[]const u8 = null,
    username: ?[]const u8 = null,
    language_code: ?[]const u8 = null,
    is_premium: ?bool = null,
    added_to_attachment_menu: ?bool = null,
};

const DocumentObject = struct {
    file_id: []const u8,
    file_unique_id: []const u8,
    file_name: ?[]const u8 = null,
    mime_type: ?[]const u8 = null,
    file_size: ?u64 = null,
    // thumbnail	PhotoSize	Optional. Thumbnail of the album cover to which the music file belongs
};

const AudioObject = struct {
    file_id: []const u8,
    file_unique_id: []const u8,
    duration: u64,
    performer: ?[]const u8 = null,
    title: ?[]const u8 = null,
    file_name: ?[]const u8 = null,
    mime_type: ?[]const u8 = null,
    file_size: ?u64 = null,
    // thumbnail	PhotoSize	Optional. Thumbnail of the album cover to which the music file belongs
};
