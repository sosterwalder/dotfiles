// Copyright 2010 Wincent Colaiuta. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#include <stdlib.h> /* for qsort() */
#include <string.h> /* for strcmp() */
#include "matcher.h"
#include "ext.h"
#include "ruby_compat.h"

// comparison function for use with qsort
int comp_alpha(const void *a, const void *b)
{
    VALUE a_val = *(VALUE *)a;
    VALUE b_val = *(VALUE *)b;
    ID to_s = rb_intern("to_s"***REMOVED***

    VALUE a_str = rb_funcall(a_val, to_s, 0***REMOVED***
    VALUE b_str = rb_funcall(b_val, to_s, 0***REMOVED***
    char *a_p = RSTRING_PTR(a_str***REMOVED***
    long a_len = RSTRING_LEN(a_str***REMOVED***
    char *b_p = RSTRING_PTR(b_str***REMOVED***
    long b_len = RSTRING_LEN(b_str***REMOVED***
    int order = 0;
    if (a_len > b_len)
  ***REMOVED***
        order = strncmp(a_p, b_p, b_len***REMOVED***
        if (order == 0)
            order = 1; // shorter string (b) wins
  ***REMOVED***
    else if (a_len < b_len)
  ***REMOVED***
        order = strncmp(a_p, b_p, a_len***REMOVED***
        if (order == 0)
            order = -1; // shorter string (a) wins
  ***REMOVED***
    else
        order = strncmp(a_p, b_p, a_len***REMOVED***
    return order;
}

// comparison function for use with qsort
int comp_score(const void *a, const void *b)
{
    VALUE a_val = *(VALUE *)a;
    VALUE b_val = *(VALUE *)b;
    ID score = rb_intern("score"***REMOVED***
    double a_score = RFLOAT_VALUE(rb_funcall(a_val, score, 0)***REMOVED***
    double b_score = RFLOAT_VALUE(rb_funcall(b_val, score, 0)***REMOVED***
    if (a_score > b_score)
        return -1; // a scores higher, a should appear sooner
    else if (a_score < b_score)
        return 1;  // b scores higher, a should appear later
    else
        return comp_alpha(a, b***REMOVED***
}

VALUE CommandTMatcher_initialize(int argc, VALUE *argv, VALUE self)
{
    // process arguments: 1 mandatory, 1 optional
    VALUE scanner, options;
    if (rb_scan_args(argc, argv, "11", &scanner, &options) == 1)
        options = Qnil;
    if (NIL_P(scanner))
        rb_raise(rb_eArgError, "nil scanner"***REMOVED***
    rb_iv_set(self, "@scanner", scanner***REMOVED***

    // check optional options hash for overrides
    VALUE always_show_dot_files = CommandT_option_from_hash("always_show_dot_files", options***REMOVED***
    if (always_show_dot_files != Qtrue)
        always_show_dot_files = Qfalse;
    VALUE never_show_dot_files = CommandT_option_from_hash("never_show_dot_files", options***REMOVED***
    if (never_show_dot_files != Qtrue)
        never_show_dot_files = Qfalse;
    rb_iv_set(self, "@always_show_dot_files", always_show_dot_files***REMOVED***
    rb_iv_set(self, "@never_show_dot_files", never_show_dot_files***REMOVED***
    return Qnil;
}

VALUE CommandTMatcher_sorted_matchers_for(VALUE self, VALUE abbrev, VALUE options)
{
    // process optional options hash
    VALUE limit_option = CommandT_option_from_hash("limit", options***REMOVED***

    // get unsorted matches
    VALUE matches = CommandTMatcher_matches_for(self, abbrev***REMOVED***

    abbrev = StringValue(abbrev***REMOVED***
    if (RSTRING_LEN(abbrev) == 0 ||
        (RSTRING_LEN(abbrev) == 1 && RSTRING_PTR(abbrev)[0] == '.'))
        // alphabetic order if search string is only "" or "."
        qsort(RARRAY_PTR(matches), RARRAY_LEN(matches), sizeof(VALUE), comp_alpha***REMOVED***
    else
        // for all other non-empty search strings, sort by score
        qsort(RARRAY_PTR(matches), RARRAY_LEN(matches), sizeof(VALUE), comp_score***REMOVED***

    // apply optional limit option
    long limit = NIL_P(limit_option) ? 0 : NUM2LONG(limit_option***REMOVED***
    if (limit == 0 || RARRAY_LEN(matches)< limit)
        limit = RARRAY_LEN(matches***REMOVED***

    // will return an array of strings, not an array of Match objects
    for (long i = 0; i < limit; i++)
  ***REMOVED***
        VALUE str = rb_funcall(RARRAY_PTR(matches)[i], rb_intern("to_s"), 0***REMOVED***
        RARRAY_PTR(matches)[i] = str;
  ***REMOVED***

    // trim off any items beyond the limit
    if (limit < RARRAY_LEN(matches))
        (void)rb_funcall(matches, rb_intern("slice!"), 2, LONG2NUM(limit),
            LONG2NUM(RARRAY_LEN(matches) - limit)***REMOVED***
    return matches;
}

VALUE CommandTMatcher_matches_for(VALUE self, VALUE abbrev)
{
    if (NIL_P(abbrev))
        rb_raise(rb_eArgError, "nil abbrev"***REMOVED***
    VALUE matches = rb_ary_new(***REMOVED***
    VALUE scanner = rb_iv_get(self, "@scanner"***REMOVED***
    VALUE always_show_dot_files = rb_iv_get(self, "@always_show_dot_files"***REMOVED***
    VALUE never_show_dot_files = rb_iv_get(self, "@never_show_dot_files"***REMOVED***
    VALUE options = Qnil;
    if (always_show_dot_files == Qtrue)
  ***REMOVED***
        options = rb_hash_new(***REMOVED***
        rb_hash_aset(options, ID2SYM(rb_intern("always_show_dot_files")), always_show_dot_files***REMOVED***
  ***REMOVED***
    else if (never_show_dot_files == Qtrue)
  ***REMOVED***
        options = rb_hash_new(***REMOVED***
        rb_hash_aset(options, ID2SYM(rb_intern("never_show_dot_files")), never_show_dot_files***REMOVED***
  ***REMOVED***
    abbrev = rb_funcall(abbrev, rb_intern("downcase"), 0***REMOVED***
    VALUE paths = rb_funcall(scanner, rb_intern("paths"), 0***REMOVED***
    for (long i = 0, max = RARRAY_LEN(paths***REMOVED*** i < max; i++)
  ***REMOVED***
        VALUE path = RARRAY_PTR(paths)[i];
        VALUE match = rb_funcall(cCommandTMatch, rb_intern("new"), 3, path, abbrev, options***REMOVED***
        if (rb_funcall(match, rb_intern("matches?"), 0) == Qtrue)
            rb_funcall(matches, rb_intern("push"), 1, match***REMOVED***
  ***REMOVED***
    return matches;
}
