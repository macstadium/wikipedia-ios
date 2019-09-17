
#include "InlineDiffJSON.h"
#include <string>
#include <sstream>
#include <iomanip>

void InlineDiffJSON::printAdd(const String &line, const String &sectionTitle, int leftLine,
                              int rightLine) {
    printAddDelete(line, HighlightType::Add, sectionTitle, rightLine);
}

void InlineDiffJSON::printDelete(const String &line, const String &sectionTitle, int leftLine,
                                 int rightLine) {
    printAddDelete(line, HighlightType::Delete, sectionTitle, rightLine);
}

void InlineDiffJSON::printAddDelete(const String &line, HighlightType highlightType,
                                    const String &sectionTitle, int lineNumber) {
    if (hasResults)
        result.append(",");

    int diffType = DiffType::Change;

    String preStr = "{\"type\": " + toString(diffType) + ", \"lineNumber\": " +
                    toString(lineNumber) + ", \"sectionTitle\": " + nullifySectionTitle(sectionTitle) +
                    ", \"moveInfo\": null, \"text\": ";

    if (line.empty()) {
        String highlightRanges = ", \"highlightRanges\": [{\"start\": 0, \"length\": 1, \"type\": " +
                                 toString(highlightType) + "}]}";

        result.append(preStr);
        result.append("\" \"");
        result.append(highlightRanges);
    } else {
        StringStream highlightRanges;
        highlightRanges << ", \"highlightRanges\": [{\"start\": 0, \"length\": " << line.length() << ", \"type\": " << highlightType << "}]}";

        result.append(preStr + "\"");
        printEscapedJSON(line);
        result.append("\"");
        result.append(highlightRanges.str());
    }

    hasResults = true;
}

void InlineDiffJSON::printWordDiff(const String &text1, const String &text2,
                                   const String &sectionTitle, int leftLine, int rightLine,
                                   bool printLeft, bool printRight, const String &srcAnchor,
                                   const String &dstAnchor, bool moveDirectionDownwards) {
    WordVector words1, words2;

    TextUtil::explodeWords(text1, words1);
    TextUtil::explodeWords(text2, words2);
    WordDiff worddiff(words1, words2, MAX_WORD_LEVEL_DIFF_COMPLEXITY);
    String word;

    bool moved = printLeft != printRight,
         isMoveSrc = moved && printLeft;

    if (hasResults)
        result.append(",");
    if (moved) {
        String moveObject;
        if (isMoveSrc) {
            LinkDirection direction = moveDirectionDownwards ? LinkDirection::Down : LinkDirection::Up;
            moveObject = "{\"id\": \"" + srcAnchor + "\", \"linkId\": \"" + dstAnchor +
                         "\", \"linkDirection\": " + toString(direction) + "}";
            result.append("{\"type\": " + toString(DiffType::MoveSource) + ", \"lineNumber\": " +
                          toString(rightLine) + ", \"sectionTitle\": " +
                          nullifySectionTitle(sectionTitle) + ", \"moveInfo\": " + moveObject + ", \"text\": \"");
        } else {
            LinkDirection direction = moveDirectionDownwards ? LinkDirection::Down : LinkDirection::Up;
            moveObject = "{\"id\": \"" + srcAnchor + "\", \"linkId\": \"" + dstAnchor +
                         "\", \"linkDirection\": " + toString(direction) + "}";
            result.append("{\"type\": " + toString(DiffType::MoveDestination) + ", \"lineNumber\": " +
                          toString(rightLine) + ", \"sectionTitle\": " +
                          nullifySectionTitle(sectionTitle) + ", \"moveInfo\": " + moveObject + ", \"text\": \"");
        }
    } else {
        result.append("{\"type\": " + toString(DiffType::Change) + ", \"lineNumber\": " +
                      toString(rightLine) + ", \"sectionTitle\": " + nullifySectionTitle(sectionTitle) +
                      ", \"moveInfo\": null, \"text\": \"");
    }
    hasResults = true;

    String rangeCalcResult;
    String ranges = "[";
    for (unsigned i = 0; i < worddiff.size(); ++i) {
        DiffOp<Word> &op = worddiff[i];
        unsigned long n;
        int j;
        if (op.op == DiffOp<Word>::copy) {
            n = op.from.size();
            for (j = 0; j < n; j++) {
                op.from[j]->get_whole(word);
                rangeCalcResult.append(word);
                printEscapedJSON(word);
            }
        } else if (op.op == DiffOp<Word>::del) {
            n = op.from.size();
            for (j = 0; j < n; j++) {
                op.from[j]->get_whole(word);

                if (!isMoveSrc) {
                    if (ranges.length() > 1)
                        ranges.append(",");
                    ranges.append("{\"start\": " + toString(rangeCalcResult.length()) + ", \"length\": " +
                                  toString(word.length()) + ", \"type\": " + toString(HighlightType::Delete) +
                                  " }");
                }
                rangeCalcResult.append(word);

                printEscapedJSON(word);
            }
        } else if (op.op == DiffOp<Word>::add) {
            if (isMoveSrc)
                continue;
            n = op.to.size();
            for (j = 0; j < n; j++) {
                op.to[j]->get_whole(word);

                if (ranges.length() > 1)
                    ranges.append(",");
                ranges.append("{\"start\": " + toString(rangeCalcResult.length()) + ", \"length\": " +
                              toString(word.length()) + ", \"type\": " + toString(HighlightType::Add) + " }");
                rangeCalcResult.append(word);

                printEscapedJSON(word);
            }
        } else if (op.op == DiffOp<Word>::change) {
            n = op.from.size();
            for (j = 0; j < n; j++) {
                op.from[j]->get_whole(word);

                if (!isMoveSrc) {
                    if (ranges.length() > 1)
                        ranges.append(",");
                    ranges.append("{\"start\": " + toString(rangeCalcResult.length()) + ", \"length\": " +
                                  toString(word.length()) + ", \"type\": " + toString(HighlightType::Delete) +
                                  " }");
                }

                rangeCalcResult.append(word);

                printEscapedJSON(word);
            }
            if (isMoveSrc)
                continue;
            n = op.to.size();
            for (j = 0; j < n; j++) {
                op.to[j]->get_whole(word);

                if (ranges.length() > 1)
                    ranges.append(",");
                ranges.append("{\"start\": " + toString(rangeCalcResult.length()) + ", \"length\": " +
                              toString(word.length()) + ", \"type\": " + toString(HighlightType::Add) + " }");
                rangeCalcResult.append(word);

                printEscapedJSON(word);
            }
        }
    }
    result.append("\", \"highlightRanges\": " + ranges + "]}");
}

void InlineDiffJSON::printBlockHeader(int leftLine, int rightLine) {
    //inline diff json not setup to print this
}

void InlineDiffJSON::printContext(const String &input, const String &sectionTitle, int leftLine,
                                  int rightLine) {
    if (hasResults)
        result.append(",");

    String preString = "{\"type\": " + toString(DiffType::Context) + ", \"lineNumber\": " +
                       toString(rightLine) + ", \"sectionTitle\": " + nullifySectionTitle(sectionTitle) +
                       ", \"moveInfo\": null, \"text\": ";

    result.append(preString + "\"");
    printEscapedJSON(input);
    result.append("\", \"highlightRanges\": []}");
    hasResults = true;
}

void InlineDiffJSON::printEscapedJSON(const String &s) {
    std::ostringstream o;
    for (auto c = s.cbegin(); c != s.cend(); c++) {
        switch (*c) {
            case '"':
                o << "\\\"";
                break;
            case '\\':
                o << "\\\\";
                break;
            case '\b':
                o << "\\b";
                break;
            case '\f':
                o << "\\f";
                break;
            case '\n':
                o << "\\n";
                break;
            case '\r':
                o << "\\r";
                break;
            case '\t':
                o << "\\t";
                break;
            default:
                if ('\x00' <= *c && *c <= '\x1f') {
                    o << "\\u"
                      << std::hex << std::setw(4) << std::setfill('0') << (int)*c;
                } else {
                    o << *c;
                }
        }
    }
    result.append(o.str());
}

const InlineDiffJSON::String InlineDiffJSON::nullifySectionTitle(const String &sectionTitle) {
    if (sectionTitle.length() == 0) {
        return "null";
    } else {
        return "\"" + sectionTitle + "\"";
    }
}

bool InlineDiffJSON::needsJSONFormat() {
    return true;
}
