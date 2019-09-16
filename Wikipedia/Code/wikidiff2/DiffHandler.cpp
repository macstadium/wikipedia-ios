
#include "DiffHandler.hpp"
#include "Wikidiff2.h"
#include "InlineDiffJSON.h"

DiffHandler::DiffHandler() {
}

std::string DiffHandler::diff(const std::string &text1, const std::string &text2) {
    try {

        InlineDiffJSON wikidiff2;

        return wikidiff2.execute(text1, text2, 2, movedParagraphDetectionCutoff(), "==+([\\s\\S])+==+");

    } catch (std::bad_alloc &e) {
        return "";
        //"Out of memory in wikidiff2_do_diff()."
    } catch (...) {
        return "";
        //Unknown exception in wikidiff2_do_diff()
    }
}
