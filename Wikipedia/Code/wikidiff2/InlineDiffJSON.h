
#ifndef INLINEDIFFJSON_H
#define INLINEDIFFJSON_H

#include <stdio.h>

#include "Wikidiff2.h"

enum DiffType {Context, Change, MoveSource, MoveDestination};
enum HighlightType {Add, Delete};
enum LinkDirection {Down, Up};

class InlineDiffJSON: public Wikidiff2 {
public:
    bool hasResults = false;
protected:
    void printAdd(const String& line, const String& sectionTitle, int leftLine, int rightLine);
    void printDelete(const String& line, const String& sectionTitle, int leftLine, int rightLine);
    void printAddDelete(const String& line, HighlightType highlightType, const String& sectionTitle, int lineNumber);
    void printWordDiff(const String& text1, const String& text2, const String& sectionTitle, int leftLine, int rightLine, bool printLeft = true, bool printRight = true, const String & srcAnchor = "", const String & dstAnchor = "", bool moveDirectionDownwards = false);
    void printBlockHeader(int leftLine, int rightLine);
    void printContext(const String& input, const String& sectionTitle, int leftLine, int rightLine);
    void printEscapedJSON(const String &s);
    const String nullifySectionTitle( const String& sectionTitle);
    bool needsJSONFormat();
};

#endif /* InlineDiffJSON_h */
