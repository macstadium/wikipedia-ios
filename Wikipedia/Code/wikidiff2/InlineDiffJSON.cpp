
#include "InlineDiffJSON.h"
#include <string>
#include <sstream>
#include <iomanip>

void InlineDiffJSON::printAdd(const String& line, const String& sectionTitle, int leftLine,
                              int rightLine)
{
    printAddDelete(line, HighlightType::Add, sectionTitle, rightLine);
}

void InlineDiffJSON::printDelete(const String& line, const String& sectionTitle, int leftLine,
                                 int rightLine)
{
    printAddDelete(line, HighlightType::Delete, sectionTitle, rightLine);
}

void InlineDiffJSON::printAddDelete(const String& line, HighlightType highlightType,
                                    const String& sectionTitle, int lineNumber) {
    if (hasResults)
        result += ",";

    int diffType = DiffType::Change;
    
    String preString = "{\"type\": " + toString(diffType) + ", \"lineNumber\": " +
        toString(lineNumber) + ", \"sectionTitle\": " + nullifySectionTitle(sectionTitle) +
        ", \"text\": ";
    
    if(line.empty()) {
        String postStr = ", \"highlightRanges\": [{\"start\": 0, \"length\": 1, \"type\": " +
            toString(highlightType) + "}]}";
        String escapedLine = "\" \"";
        printWrappedLine(preString.c_str(), escapedLine, postStr.c_str());
    } else {
        StringStream highlightRanges;
        highlightRanges << ", \"highlightRanges\": [{\"start\": 0, \"length\": " << line.length() <<
            ", \"type\": " << highlightType << "}]}";
        
        result += preString + "\"";
        printEscapedJSON(line);
        result += "\"";
        result += highlightRanges.str().c_str();
    }
    
    hasResults = true;
}

void InlineDiffJSON::printWordDiff(const String& text1, const String& text2,
                                   const String& sectionTitle, int leftLine, int rightLine,
                                   bool printLeft, bool printRight, const String & srcAnchor,
                                   const String & dstAnchor, bool moveDirectionDownwards)
{
    WordVector words1, words2;
    
    TextUtil::explodeWords(text1, words1);
    TextUtil::explodeWords(text2, words2);
    WordDiff worddiff(words1, words2, MAX_WORD_LEVEL_DIFF_COMPLEXITY);
    String word;
    
    bool moved = printLeft != printRight,
    isMoveSrc = moved && printLeft;
    
    if (hasResults)
        result += ",";
    if (moved) {
        String moveObject;
        if (isMoveSrc) {
            LinkDirection direction = moveDirectionDownwards ?
                LinkDirection::Down : LinkDirection::Up;
            moveObject = "{\"id\": \"" + srcAnchor + "\", \"linkId\": \"" + dstAnchor +
                "\", \"linkDirection\": " + toString(direction) + "}";
            result += "{\"type\": " + toString(DiffType::MoveSource) + ", \"lineNumber\": " +
                toString(rightLine) + ", \"moveInfo\": " + moveObject + ", \"sectionTitle\": " +
                nullifySectionTitle(sectionTitle) + ", \"text\": \"";
        } else {
            LinkDirection direction = moveDirectionDownwards ?
                LinkDirection::Down : LinkDirection::Up;
            moveObject = "{\"id\": \"" + srcAnchor + "\", \"linkId\": \"" + dstAnchor +
                "\", \"linkDirection\": " + toString(direction) + "}";
            result += "{\"type\": " + toString(DiffType::MoveDestination) + ", \"lineNumber\": " +
                toString(rightLine) + ", \"moveInfo\": " + moveObject + ", \"sectionTitle\": " +
                nullifySectionTitle(sectionTitle) + ", \"text\": \"";
        }
    } else {
        result += "{\"type\": " + toString(DiffType::Change) + ", \"lineNumber\": " +
            toString(rightLine) + ", \"sectionTitle\": " + nullifySectionTitle(sectionTitle) +
            ", \"text\": \"";
    }
    hasResults = true;
    
    String rangeCalcResult;
    String ranges = "[";
    for (unsigned i = 0; i < worddiff.size(); ++i) {
        DiffOp<Word> & op = worddiff[i];
        unsigned long n;
        int j;
        if (op.op == DiffOp<Word>::copy) {
            n = op.from.size();
            for (j=0; j<n; j++) {
                op.from[j]->get_whole(word);
                rangeCalcResult += word;
                printEscapedJSON(word);
            }
        } else if (op.op == DiffOp<Word>::del) {
            n = op.from.size();
            for (j=0; j<n; j++) {
                op.from[j]->get_whole(word);
                
                if (ranges.length() > 1)
                    ranges += ",";
                ranges += "{\"start\": " + toString(rangeCalcResult.length()) + ", \"length\": " +
                    toString(word.length()) + ", \"type\": " + toString(HighlightType::Delete) +
                    " }";
                rangeCalcResult += word;
                
                printEscapedJSON(word);
            }
        } else if (op.op == DiffOp<Word>::add) {
            if (isMoveSrc)
                continue;
            n = op.to.size();
            for (j=0; j<n; j++) {
                op.to[j]->get_whole(word);
                
                if (ranges.length() > 1)
                    ranges += ",";
                ranges += "{\"start\": " + toString(rangeCalcResult.length()) + ", \"length\": " +
                    toString(word.length()) + ", \"type\": " + toString(HighlightType::Add) + " }";
                rangeCalcResult += word;
                
                printEscapedJSON(word);
            }
        } else if (op.op == DiffOp<Word>::change) {
            n = op.from.size();
            for (j=0; j<n; j++) {
                op.from[j]->get_whole(word);
                
                if (ranges.length() > 1)
                    ranges += ",";
                ranges += "{\"start\": " + toString(rangeCalcResult.length()) + ", \"length\": " +
                    toString(word.length()) + ", \"type\": " + toString(HighlightType::Delete) +
                    " }";
                rangeCalcResult += word;
                
                printEscapedJSON(word);
            }
            if (isMoveSrc)
                continue;
            n = op.to.size();
            for (j=0; j<n; j++) {
                op.to[j]->get_whole(word);
                
                if (ranges.length() > 1)
                    ranges += ",";
                ranges += "{\"start\": " + toString(rangeCalcResult.length()) + ", \"length\": " +
                    toString(word.length()) + ", \"type\": " + toString(HighlightType::Add) + " }";
                rangeCalcResult += word;
                
                printEscapedJSON(word);
            }
        }
    }
    result += "\", \"highlightRanges\": " + ranges + "]}";
}

void InlineDiffJSON::printBlockHeader(int leftLine, int rightLine)
{
    //inline diff json not setup to print this
}

void InlineDiffJSON::printContext(const String & input, const String& sectionTitle, int leftLine,
                                  int rightLine)
{
    if (hasResults)
        result += ",";
    
    String preString = "{\"type\": " + toString(DiffType::Context) + ", \"lineNumber\": " +
        toString(rightLine) + ", \"sectionTitle\": " + nullifySectionTitle(sectionTitle) +
        ", \"text\": ";

    result += preString + "\"";
    printEscapedJSON(input);
    result += "\", \"highlightRanges\": []}";
    hasResults = true;
}

void InlineDiffJSON::printWrappedLine(const char* pre, const String& line, const char* post)
{
    result += pre;
    if (line.empty()) {
        result += " ";
    } else {
        result.append(line);
    }
    result += post;
}

void InlineDiffJSON::printEscapedJSON(const String &s) {
    std::ostringstream o;
    for (auto c = s.cbegin(); c != s.cend(); c++) {
        switch (*c) {
            case '"': o << "\\\""; break;
            case '\\': o << "\\\\"; break;
            case '\b': o << "\\b"; break;
            case '\f': o << "\\f"; break;
            case '\n': o << "\\n"; break;
            case '\r': o << "\\r"; break;
            case '\t': o << "\\t"; break;
            default:
                if ('\x00' <= *c && *c <= '\x1f') {
                    o << "\\u"
                    << std::hex << std::setw(4) << std::setfill('0') << (int)*c;
                } else {
                    o << *c;
                }
        }
    }
    result += o.str();
}


std::string InlineDiffJSON::nullifySectionTitle(const std::string &sectionTitle) {
    if (sectionTitle.length() == 0) {
        return "null";
    } else {
        return "\"" + sectionTitle + "\"";
    }
}

bool InlineDiffJSON::needsJSONFormat()
{
    return true;
}
