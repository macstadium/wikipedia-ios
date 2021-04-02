#import <WMF/MWKLanguageLinkController_Private.h>
#import <WMF/WMF-Swift.h>
#import <WMF/MWKDataStore.h>

NS_ASSUME_NONNULL_BEGIN

NSString *const WMFPreferredLanguagesDidChangeNotification = @"WMFPreferredLanguagesDidChangeNotification";

NSString *const WMFAppLanguageDidChangeNotification = @"WMFAppLanguageDidChangeNotification";

NSString *const WMFPreferredLanguagesChangeTypeKey = @"WMFPreferredLanguagesChangeTypeKey";
NSString *const WMFPreferredLanguagesLastChangedLanguageKey = @"WMFPreferredLanguagesLastChangedLanguageKey";

static NSString *const WMFPreviousLanguagesKey = @"WMFPreviousSelectedLanguagesKey";

@interface MWKLanguageLinkController ()

@property (weak, nonatomic) NSManagedObjectContext *moc;

@end

@implementation MWKLanguageLinkController

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc {
    if (self = [super init]) {
        self.moc = moc;
    }
    return self;
}

#pragma mark - Getters & Setters

+ (NSDictionary<NSString *, NSArray<MWKLanguageLink *> *> *)allLanguageVariantsBySiteLanguageCode {
    /// Separate static dictionary here so the dictionary is only bridged once
    static dispatch_once_t onceToken;
    static NSDictionary<NSString *, NSArray<MWKLanguageLink *> *> *allLanguageVariantsBySiteLanguageCode;
    dispatch_once(&onceToken, ^{
        allLanguageVariantsBySiteLanguageCode = WikipediaLookup.allLanguageVariantsByWikipediaLanguageCode;
    });
    return allLanguageVariantsBySiteLanguageCode;
}

+ (NSArray<MWKLanguageLink *> *)allLanguages {
    /// Separate static array here so the array is only bridged once and variant substitution happens once
    static dispatch_once_t onceToken;
    static NSArray<MWKLanguageLink *> *allLanguages;
    dispatch_once(&onceToken, ^{
        allLanguages = [MWKLanguageLinkController languagesReplacingSiteLanguagesWithVariants:WikipediaLookup.allLanguageLinks];
    });
    return allLanguages;
}

/// Since MWKLanguageLink instances represent a language choice in the user-interface, language variants must be included.
/// The autogenerated all languages list and the list of languges for an article both include only site languages, not variants.
/// This method takes an array of site language links and replaces the site language with the language variants for sites with variants.
+ (NSArray<MWKLanguageLink *> *)languagesReplacingSiteLanguagesWithVariants:(NSArray<MWKLanguageLink *> *)languages {
    NSMutableArray *tempResult = [[NSMutableArray alloc] init];
    for (MWKLanguageLink *language in languages) {
        NSAssert((language.languageVariantCode == nil && ![language.languageVariantCode isEqualToString:@""]), @"The method %s should only be called with MWKLanguageLink objects with a nil or empty-string languageVariantCode", __PRETTY_FUNCTION__);
        NSArray<MWKLanguageLink *> *variants = [MWKLanguageLinkController allLanguageVariantsBySiteLanguageCode][language.languageCode];
        if (variants) {
            [tempResult addObjectsFromArray:variants];
        } else {
            [tempResult addObject:language];
        }
    }
    return [tempResult copy];
}

- (NSArray<MWKLanguageLink *> *)allLanguages {
    return [MWKLanguageLinkController allLanguages];
}

- (nullable MWKLanguageLink *)languageForContentLanguageCode:(NSString *)contentLanguageCode {
    return [self.allLanguages wmf_match:^BOOL(MWKLanguageLink *obj) {
        return [obj.contentLanguageCode isEqual:contentLanguageCode];
    }];
}

- (nullable NSString *)preferredLanguageVariantCodeForLanguageCode:(nullable NSString *)languageCode {
    if (!languageCode) {
        return nil;
    }

    // Find first with matching language code in app preferred languages
    MWKLanguageLink *matchingLanguageLink = [self.preferredLanguages wmf_match:^BOOL(MWKLanguageLink *obj) {
        return [obj.languageCode isEqual:languageCode];
    }];

    // If the matching link does not have a language variant code, the language does not have variants. Return nil.
    if (matchingLanguageLink) {
        return matchingLanguageLink.languageVariantCode ?: nil;
    }

    // If not found in the app's preferred languages, get the best guess from the user's OS settings.
    return [NSLocale wmf_bestLanguageVariantCodeForLanguageCode:languageCode];
}

- (nullable MWKLanguageLink *)appLanguage {
    return [self.preferredLanguages firstObject];
}

- (NSArray<MWKLanguageLink *> *)preferredLanguages {
    NSArray *preferredLanguageCodes = [self readPreferredLanguageCodes];
    return [preferredLanguageCodes wmf_mapAndRejectNil:^id(NSString *langString) {
        return [self.allLanguages wmf_match:^BOOL(MWKLanguageLink *langLink) {

            //Note, sometimes the device iOS language codes will return a code that doesn't line up with the Wikipedia language codes we have set,
            //so we are also checking for a match against the altISOCode (currently only set for "no.wikipedia.org")
            //Fixes https://phabricator.wikimedia.org/T276645
            return [langLink.contentLanguageCode isEqualToString:langString] ||
                                                (langLink.altISOCode &&
                                                [langLink.altISOCode isEqualToString:langString]);
        }];
    }];
}

- (NSArray<NSURL *> *)preferredSiteURLs {
    return [[self preferredLanguages] wmf_mapAndRejectNil:^NSURL *_Nullable(MWKLanguageLink *_Nonnull obj) {
        return [obj siteURL];
    }];
}

- (NSArray<MWKLanguageLink *> *)otherLanguages {
    return [self.allLanguages wmf_select:^BOOL(MWKLanguageLink *langLink) {
        return ![self.preferredLanguages containsObject:langLink];
    }];
}

#pragma mark - Preferred Language Management

- (void)appendPreferredLanguage:(MWKLanguageLink *)language {
    NSParameterAssert(language);
    NSMutableArray<NSString *> *langCodes = [[self readPreferredLanguageCodes] mutableCopy];
    [langCodes removeObject:language.contentLanguageCode];
    [langCodes addObject:language.contentLanguageCode];
    [self savePreferredLanguageCodes:langCodes changeType:WMFPreferredLanguagesChangeTypeAdd changedLanguage:language];
}

- (void)reorderPreferredLanguage:(MWKLanguageLink *)language toIndex:(NSInteger)newIndex {
    NSMutableArray<NSString *> *langCodes = [[self readPreferredLanguageCodes] mutableCopy];
    NSAssert(newIndex < (NSInteger)[langCodes count], @"new language index is out of range");
    if (newIndex >= (NSInteger)[langCodes count]) {
        return;
    }
    NSInteger oldIndex = (NSInteger)[langCodes indexOfObject:language.contentLanguageCode];
    NSAssert(oldIndex != NSNotFound, @"Language is not a preferred language");
    if (oldIndex == NSNotFound) {
        return;
    }
    [langCodes removeObject:language.contentLanguageCode];
    [langCodes insertObject:language.contentLanguageCode atIndex:(NSUInteger)newIndex];
    [self savePreferredLanguageCodes:langCodes changeType:WMFPreferredLanguagesChangeTypeReorder changedLanguage:language];
}

- (void)removePreferredLanguage:(MWKLanguageLink *)language {
    NSMutableArray<NSString *> *langCodes = [[self readPreferredLanguageCodes] mutableCopy];
    [langCodes removeObject:language.contentLanguageCode];
    [self savePreferredLanguageCodes:langCodes changeType:WMFPreferredLanguagesChangeTypeRemove changedLanguage:language];
}

#pragma mark - Reading/Saving Preferred Language Codes

- (NSArray<NSString *> *)readSavedPreferredLanguageCodes {
    return [self readSavedPreferredLanguageCodesInManagedObjectContext:self.moc];
}
    
- (NSArray<NSString *> *)readSavedPreferredLanguageCodesInManagedObjectContext:(NSManagedObjectContext *)moc {
    __block NSArray<NSString *> *preferredLanguages = nil;
    [moc performBlockAndWait:^{
        preferredLanguages = [moc wmf_arrayValueForKey:WMFPreviousLanguagesKey] ?: @[];
    }];
    return preferredLanguages;
}

- (NSArray<NSString *> *)readPreferredLanguageCodes {
    NSMutableArray<NSString *> *preferredLanguages = [[self readSavedPreferredLanguageCodes] mutableCopy];

    if (preferredLanguages.count == 0) {
        // When language variant feature is turned on, the flag will be removed and use NSLocale.wmf_preferredWikipediaLanguageCodes
        NSArray<NSString *> *osLanguages = WikipediaLookup.languageVariantsEnabled ? NSLocale.wmf_preferredWikipediaLanguageCodes : NSLocale.wmf_preferredLocaleLanguageCodes;
        [osLanguages enumerateObjectsWithOptions:0
                                      usingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                                          if (![preferredLanguages containsObject:obj]) {
                                              [preferredLanguages addObject:obj];
                                          }
                                      }];
    }
    return [preferredLanguages wmf_reject:^BOOL(id obj) {
        return [obj isEqual:[NSNull null]];
    }];
}

- (void)savePreferredLanguageCodes:(NSArray<NSString *> *)languageCodes changeType:(WMFPreferredLanguagesChangeType)changeType changedLanguage:(MWKLanguageLink *)changedLanguage {
    [self savePreferredLanguageCodes:languageCodes changeType:changeType changedLanguage:changedLanguage inManagedObjectContext:self.moc];
}

- (void)savePreferredLanguageCodes:(NSArray<NSString *> *)languageCodes changeType:(WMFPreferredLanguagesChangeType)changeType changedLanguage:(nullable MWKLanguageLink *)changedLanguage inManagedObjectContext:(NSManagedObjectContext *)moc {
    NSString *previousAppContentLanguageCode = self.appLanguage.contentLanguageCode;
    [moc performBlockAndWait:^{
        [moc wmf_setValue:languageCodes forKey:WMFPreviousLanguagesKey];
        NSError *preferredLanguageCodeSaveError = nil;
        if (![moc save:&preferredLanguageCodeSaveError]) {
            DDLogError(@"Error saving preferred languages: %@", preferredLanguageCodeSaveError);
        }
    }];
    
    // Send notifications only if there is a change type and changed language
    // Used to avoid sending notifications during language variant migration
    if (changeType && changedLanguage) {
        [[NSNotificationCenter defaultCenter] postNotificationName:MWKLanguageFilterDataSourceLanguagesDidChangeNotification object: self];
        NSDictionary *userInfo = @{WMFPreferredLanguagesChangeTypeKey: @(changeType), WMFPreferredLanguagesLastChangedLanguageKey: changedLanguage};
        [[NSNotificationCenter defaultCenter] postNotificationName:WMFPreferredLanguagesDidChangeNotification object:self userInfo:userInfo];
        if (self.appLanguage.contentLanguageCode && ![self.appLanguage.contentLanguageCode isEqualToString:previousAppContentLanguageCode]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:WMFAppLanguageDidChangeNotification object:self];
        }
    }
}

// Reminder: "resetPreferredLanguages" is for testing only!
- (void)resetPreferredLanguages {
    [self.moc performBlockAndWait:^{
        [self.moc wmf_setValue:nil forKey:WMFPreviousLanguagesKey];
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:MWKLanguageFilterDataSourceLanguagesDidChangeNotification object: self];
    [[NSNotificationCenter defaultCenter] postNotificationName:WMFPreferredLanguagesDidChangeNotification object:self];
}

- (void)getPreferredContentLanguageCodes:(void (^)(NSArray<NSString *> *))completion {
    [self.moc performBlock:^{
        completion([self readPreferredLanguageCodes]);
    }];
}

- (void)getPreferredLanguageCodes:(void (^)(NSArray<NSString *> *))completion {
    NSArray<NSURL *> *preferredSiteURLs = [self preferredSiteURLs];
    NSMutableSet<NSString *> *preferredWikiCodes = [[NSMutableSet alloc] init];
    for (NSURL *siteURL in preferredSiteURLs) {
        [preferredWikiCodes addObject: siteURL.wmf_language];
    }
    
    completion(preferredWikiCodes.allObjects);
}

// This method can only be safely called from the main app target, as an extension's standard `NSUserDefaults` are independent from the main app and other targets.
+ (void)migratePreferredLanguagesToManagedObjectContext:(NSManagedObjectContext *)moc {
    NSArray *preferredLanguages = [[NSUserDefaults standardUserDefaults] arrayForKey:WMFPreviousLanguagesKey];
    [moc wmf_setValue:preferredLanguages forKey:WMFPreviousLanguagesKey];
}

- (void)migratePreferredLanguagesToLanguageVariants:(NSDictionary<NSString *, NSString *> *)languageMapping  inManagedObjectContext:(NSManagedObjectContext *)moc {
    NSArray<NSString *> *preferredLanguageCodes = [[self readSavedPreferredLanguageCodesInManagedObjectContext:moc] copy];
    NSMutableArray<NSString *> *updatedLanguageCodes = [preferredLanguageCodes mutableCopy];
    BOOL languageCodesChanged = NO;
    NSInteger currentIndex = 0;
    for (NSString *languageCode in preferredLanguageCodes) {
        NSString *migratedLanguageCode = languageMapping[languageCode];
        if (migratedLanguageCode) {
            [updatedLanguageCodes replaceObjectAtIndex:currentIndex withObject:languageMapping[languageCode]];
            languageCodesChanged = YES;
        }
        currentIndex++;
    }
    
    if (languageCodesChanged) {
        // No changeType and nil changedLanguage will skip sending of notifications that preferred languages changed
        [self savePreferredLanguageCodes:updatedLanguageCodes changeType:0 changedLanguage:nil inManagedObjectContext:moc];
    }
}

@end

#pragma mark -

@implementation MWKLanguageLinkController (ArticleLanguageLinkVariants)

/// Given an article URL, if the URL has a language variant, an array of MWKLanguageLink instances of the remaining variants for that language is returned.
/// This allows a user viewing an article in one language variant to choose to view the article using another variant.
/// If the provided URL does not have a language variant, returns an empty array.
- (NSArray<MWKLanguageLink *> *)remainingLanguageLinkVariantsForArticleURL:(NSURL *)articleURL {
    // If the original URL is a variant, include the other variants as choices
    NSString *originalURLLanguageVariantCode = articleURL.wmf_languageVariantCode;
    NSString *originalURLLanguageCode = articleURL.wmf_language;
    NSMutableArray *remainingLanguageVariantLinks = [[NSMutableArray alloc] init];
    if (originalURLLanguageVariantCode && originalURLLanguageCode) {
        NSArray<MWKLanguageLink *> *variants = [MWKLanguageLinkController allLanguageVariantsBySiteLanguageCode][originalURLLanguageCode];
        if (variants) {
            for (MWKLanguageLink *variant in variants) {
                if (![variant.languageVariantCode isEqualToString:originalURLLanguageVariantCode]) {
                    MWKLanguageLink *articleVariant = [variant languageLinkWithPageTitleText:articleURL.wmf_titleWithUnderscores];
                    [remainingLanguageVariantLinks addObject:articleVariant];
                }
            }
        }
    }
    return remainingLanguageVariantLinks;
}

/// Given an array of article language links, returns an array where any language with variants is replaced with one article language link per variant
- (NSArray<MWKLanguageLink *> *)languageLinksReplacingArticleLanguageLinksWithVariants:(NSArray<MWKLanguageLink *> *)articleLanguageLinks {
    NSMutableArray *processedLanguageLinks = [[NSMutableArray alloc] init];
    for (MWKLanguageLink *language in articleLanguageLinks) {
        NSAssert((language.languageVariantCode == nil && ![language.languageVariantCode isEqualToString:@""]), @"The method %s should only be called with MWKLanguageLink objects with a nil or empty-string languageVariantCode", __PRETTY_FUNCTION__);
        NSArray<MWKLanguageLink *> *variants = [MWKLanguageLinkController allLanguageVariantsBySiteLanguageCode][language.languageCode];
        if (variants) {
            for (MWKLanguageLink *variant in variants) {
                MWKLanguageLink *articleVariant = [variant languageLinkWithPageTitleText:language.pageTitleText];
                [processedLanguageLinks addObject:articleVariant];
            }
        } else {
            [processedLanguageLinks addObject:language];
        }
    }
    return processedLanguageLinks;
}

- (NSArray<MWKLanguageLink *> *)articleLanguageLinksWithVariantsFromArticleURL:(NSURL *)articleURL articleLanguageLinks:(NSArray<MWKLanguageLink *> *)articleLanguageLinks {

    // If the original URL is a variant, include the other variants as choices
    NSArray *remainingLanguageLinkVariants = [self remainingLanguageLinkVariantsForArticleURL:articleURL];

    // If any of the available languages has variants, substitute in the variants.
    NSArray *articleLanguageLinksWithVariants = [self languageLinksReplacingArticleLanguageLinksWithVariants:articleLanguageLinks];

    return [articleLanguageLinksWithVariants arrayByAddingObjectsFromArray:remainingLanguageLinkVariants];
}

@end

#pragma mark -

@implementation MWKLanguageLinkController (LayoutDirectionAdditions)

+ (BOOL)isLanguageRTLForContentLanguageCode:(nullable NSString *)contentLanguageCode {
    return contentLanguageCode && [[MWKLanguageLinkController rtlLanguages] containsObject:contentLanguageCode];
}

+ (NSString *)layoutDirectionForContentLanguageCode:(nullable NSString *)contentLanguageCode {
    return [MWKLanguageLinkController isLanguageRTLForContentLanguageCode:contentLanguageCode] ? @"rtl" : @"ltr";
}

+ (UISemanticContentAttribute)semanticContentAttributeForContentLanguageCode:(nullable NSString *)contentLanguageCode {
    if (!contentLanguageCode) {
        return UISemanticContentAttributeUnspecified;
    }
    return [MWKLanguageLinkController isLanguageRTLForContentLanguageCode:contentLanguageCode] ? UISemanticContentAttributeForceRightToLeft : UISemanticContentAttributeForceLeftToRight;
}

/*
 * IMPORTANT: At present no RTL languages have language variants.
 * The public methods in this category accept a contentLanguageCode, but in current usage always accept a language code
 * which does not take language variants into account. If a language variant is added to the set returned by this method, the call sites
 * of the public methods in this category need to be updated to ensure that the content language code is passed in.
 *
 * Note also that if a language with variants is RTL, each RTL variant must be added to the set.
 */
+ (NSSet *)rtlLanguages {
    static dispatch_once_t onceToken;
    static NSSet *rtlLanguages;
    dispatch_once(&onceToken, ^{
        rtlLanguages = [NSSet setWithObjects:@"arc", @"arz", @"ar", @"azb", @"bcc", @"bqi", @"ckb", @"dv", @"fa", @"glk", @"lrc", @"he", @"khw", @"ks", @"mzn", @"nqo", @"pnb", @"ps", @"sd", @"ug", @"ur", @"yi", nil];
    });
    return rtlLanguages;
}

@end

NS_ASSUME_NONNULL_END
