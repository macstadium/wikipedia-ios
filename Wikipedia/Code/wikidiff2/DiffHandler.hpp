
#ifndef DiffHandler_hpp
#define DiffHandler_hpp

#include <stdio.h>
#include <string>
#include <list>

/** Set WD2_USE_STD_ALLOCATOR depending on whether we're compiling as a PHP module or not */
#if defined(HAVE_CONFIG_H)
    #define WD2_ALLOCATOR PhpAllocator
    #include "php_cpp_allocator.h"
#else
    #define WD2_ALLOCATOR std::allocator
#endif

class DiffHandler {
public:
    typedef std::list<int, WD2_ALLOCATOR<int>> IntList;
    DiffHandler();
    std::string diff(const std::string & text1, const std::string & text2);
};

#endif /* DiffHandler_hpp */
