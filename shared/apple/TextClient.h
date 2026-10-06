#import <Foundation/Foundation.h>

@protocol LINGYAOTextClient <NSObject>
- (void)insertText:(id)text replacementRange:(NSRange)range;
- (void)setMarkedText:(id)text selectionRange:(NSRange)selection replacementRange:(NSRange)replacement;
@optional
// NSTextInputClient-compatible context queries. Hosts that cannot expose
// document context may omit these; callers must treat the result as unknown.
- (NSRange)selectedRange;
- (NSAttributedString *)attributedSubstringFromRange:(NSRange)range;
@end

typedef NS_ENUM(NSInteger, LINGYAOInlinePreeditStyle) {
    LINGYAOInlinePreeditStyleRaw,
    LINGYAOInlinePreeditStylePinyin,
    LINGYAOInlinePreeditStyleEmpty,
};

void LINGYAOApplyTransition(NSDictionary *transition, id<LINGYAOTextClient> client);
/// Applies a transition using the shared inline preedit display preference.
/// The legacy entry point above remains the pinyin-display default for callers
/// that do not consume shared preferences yet.
void LINGYAOApplyTransitionWithPreeditStyle(NSDictionary *transition, id<LINGYAOTextClient> client,
                                          LINGYAOInlinePreeditStyle style);
/// The same, carrying a closing mark the host owes the document.
///
/// Paired punctuation puts the caret between the two marks, and IMK has no way to move a client's
/// insertion point. The opening mark is committed as usual and the closing one rides in the marked
/// text after the caret until the composition ends, so what the user sees is `（|）` and then
/// `（你好|）`. Passing nil is the ordinary case and behaves exactly as the call above.
void LINGYAOApplyTransitionWithPendingClosing(NSDictionary *transition, id<LINGYAOTextClient> client,
                                            LINGYAOInlinePreeditStyle style, NSString *closing);
/// The same, for a host that knows whether the client still holds marked text this host wrote.
///
/// Every call into an IMK client is a synchronous round trip into another process, and a focus change makes one while the client is itself blocked waiting for the input method to activate: the two stall each other until IMK's XPC timeout, which is the 1-3 s hitch Chrome shows on every tab or window switch. Clearing marked text that was never set is the one write that changes nothing, so with nothing to commit, nothing to mark and `*clientHasMarkedText` NO the client is not called at all. A commit still sends the clear after it, exactly as above. `*clientHasMarkedText` is updated to what the client holds afterwards; NULL means unknown and always sends.
void LINGYAOApplyTransitionTrackingMarkedText(NSDictionary *transition, id<LINGYAOTextClient> client,
                                            LINGYAOInlinePreeditStyle style, NSString *closing,
                                            BOOL *clientHasMarkedText);
// UTF-16 display offset shared by marked text and the candidate preedit row.
NSUInteger LINGYAOPreeditCaretPosition(NSString *editing, NSString *preedit, id position);

// Returns the single UTF-16 character immediately following the selection,
// or nil when the host cannot safely expose document context.
NSString * LINGYAOTextClientFollowingCharacter(id<LINGYAOTextClient> client);
/// Returns the Unicode scalar immediately preceding the selection, or zero when
/// the host cannot safely expose document context.
uint32_t LINGYAOTextClientPrecedingUnicodeScalar(id<LINGYAOTextClient> client);
