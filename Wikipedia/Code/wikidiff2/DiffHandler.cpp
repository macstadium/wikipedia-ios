
#include "DiffHandler.hpp"
#include "Wikidiff2.h"
#include "InlineDiffJSON.h"

DiffHandler::DiffHandler() {
}

std::string DiffHandler::diff(const std::string &text1, const std::string &text2) {
    try {

        InlineDiffJSON wikidiff2;
        String sectionOffsets = "3907 4592 5844 8605 8703 9251 9346 10447 11702 13065 14089 19414 22884 26748 30386 33055 36004 36051 38782 43559 44201 44214 46276 49753 52108 55106 56745 58396 62596 71311 75283 76144 81148 88208 96709 98309 98577 102056 102299 105954 107174 107719 107743 122001 122829 123443";
        return wikidiff2.execute(text1, text2, sectionOffsets, 2, movedParagraphDetectionCutoff());

    } catch (std::bad_alloc &e) {
        return "";
        //"Out of memory in wikidiff2_do_diff()."
    } catch (...) {
        return "";
        //Unknown exception in wikidiff2_do_diff()
    }
}
