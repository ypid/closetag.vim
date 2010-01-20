" File: closetag.vim
" Summary: Functions and mappings to close open HTML/XML tags
" Uses: <C-_> -- close matching open tag
" Author: Steven Mueller <diffusor@ugcs.caltech.edu>
" Last Modified: Tue May 24 13:29:48 PDT 2005 
" Version: 0.9.1
" XXX - breaks if close attempted while XIM is in preedit mode
" TODO - allow usability as a global plugin -
"    Add g:unaryTagsStack - always contains html tags settings
"    and g:closetag_default_xml - user should define this to default to xml
"    When a close is attempted but b:unaryTagsStack undefined,
"    use b:closetag_html_style to determine if the file is to be treated
"    as html or xml.  Failing that, check the filetype for xml or html.
"    Finally, default to g:closetag_html_style.
"    If the file is html, let b:unaryTagsStack=g:unaryTagsStack
"    otherwise, let b:unaryTagsStack=""
" TODO - make matching work for all comments
"  -- kinda works now, but needs syn sync minlines to be very long
"  -- Only check whether in syntax in the beginning, then store comment tags
"  in the tagstacks to determine whether to move into or out of comment mode
" TODO - The new normal mode mapping clears recent messages with its <ESC>, and
" it doesn't fix the null-undo issue for vim 5.7 anyway.
" TODO - make use of the following neat features:
"  -- the ternary ?: operator
"  -- :echomsg and :echoerr
"  -- curly brace expansion for variables and function name definitions?
"  -- check up on map <blah> \FuncName
"
" Description:
" This script eases redundant typing when writing html or xml files (even if
" you're very good with ctrl-p and ctrl-n  :).  Hitting ctrl-_ will initiate a
" search for the most recent open tag above that is not closed in the
" intervening space and then insert the matching close tag at the cursor.  In
" normal mode, the close tag is inserted one character after cursor rather than
" at it, as if a<C-_> had been used.  This allows putting close tags at the
" ends of lines while in normal mode, but disallows inserting them in the
" first column.
"
" For HTML, a configurable list of tags are ignored in the matching process.
" By default, the following tags will not be matched and thus not closed
" automatically: area, base, br, dd, dt, hr, img, input, link, meta, and
" param.
"
" For XML, all tags must have a closing match or be terminated by />, as in
" <empty-element/>.  These empty element tags are ignored for matching.
"
" Comment checking is now handled by vim's internal syntax checking.  If tag
" closing is initiated outside a comment, only tags outside of comments will
" be matched.  When closing tags in comments, only tags within comments will
" be matched, skipping any non-commented out code (wee!).  However, the
" process of determining the syntax ID of an arbitrary position can still be
" erroneous if a comment is not detected because the syntax highlighting is
" out of sync, or really slow if syn sync minlines is large.
" Set the b:closetag_disable_synID variable to disable this feature if you
" have really big chunks of comment in your code and closing tags is too slow.
" 
" If syntax highlighting is not enabled, comments will not be handled very
" well.  Commenting out HTML in certain ways may cause a "tag mismatch"
" message and no completion.  For example, '<!--a href="blah">link!</a-->'
" between the cursor and the most recent unclosed open tag above causes
" trouble.  Properly matched well formed tags in comments don't cause a
" problem.
"
" Install:
" To use, place this file in your standard vim plugin directory. You may force
" HTML style tag matching by first defining the g:closetag_html_style variable.
" Otherwise, the default is XML style tag matching.
"
" Example:
"   :let g:closetag_html_style=1
"   :source ~/.vim/scripts/closetag.vim
"
" Also, set noignorecase for html files or edit b:unaryTagsStack to match your
" capitalization style.  You may set this variable before or after loading the
" script, or simply change the file itself.
"
" Configuration Variables:
"
" g:unaryTagsStack        Global setting, can be overridden by: 
" b:unaryTagsStack        Buffer local string containing a whitespace
"                         seperated list of element names that should be
"                         ignored while finding matching closetags.  Checking
"                         is done according to the current setting of the
"                         ignorecase option.
"
" g:closetag_html_style   Define this (as with let g:closetag_html_style=1)
"                         and source the script to set the
"                         unaryTagsStack to its default value for html.
"
" b:closetag_disable_synID  Define this to disable comment checking if tag
"                         closing is too slow.  This can be set or unset
"                         without having to source again.
"
" g:closetag_fill_content Set to 0 if you don't want to jump inside an inserted
"                         tag to fill in content in case there is none yet. 
"
" Changelog:
" Jan 21, 2010 by Ingo Karkat
"   * ENH: In insert mode, jump inside tag if the tag has no content; i.e. the
"     corresponding open tag is only separated by whitespace from the closing
"     tag. Any whitespace spacing style is mirrored: If there are <Tab>
"     characters after the open tag, a <Tab> is prepended before the closing
"     tag, too. Same for spaces and newline. (Vim 7+ only.) 
"     If you don't want to insert content, invoke the CTRL-_ mapping immediately
"     again; it'll make the cursor jump to after the end tag. 
"   * Made g:IsKeywordBak script-local. 
"
" Jan 19, 2010 by Ingo Karkat
"   * Modified normal mode <C-_> mapping to detect whether the cursor is on the
"     beginning of a tag, and inserts / appends accordingly. (Vim 7+ only.) 
"
" Dec 02, 2009 by Ingo Karkat
"   * Added 'embed' tag to g:unaryTagsStack. 
"
" Nov 04, 2009 by Ingo Karkat
"   * Added global default setting g:unaryTagsStack that is overriden by
"     b:unaryTagsStack to avoid those nasty script errors in filetypes for which
"     the script hasn't been sourced. 
"     The script is now a Vim plugin, and is sourced on Vim startup. 
"   * Adapted g:closetag_html_style to more "modern" HTML. 
"   * Changed :imap to map-expr for Vim 7+. 
"   * Added highlighting for "no opening tags" and improved error highlighting
"     elsewhere. 
"
" May 24, 2005 Tuesday
"   * Changed function names to be script-local to avoid conflicts with other
"     scripts' stack implementations.
"
" June 07, 2001 Thursday
"   * Added comment handling.  Currently relies on synID, so if syn sync
"     minlines is small, the chance for failure is high, but if minlines is
"     large, tagclosing becomes rather slow...
"
"   * Changed normal mode closetag mapping to use <C-R> in insert mode
"     rather than p in normal mode.  This has 2 implications:
"       - Tag closing no longer clobbers the unnamed register
"       - When tag closing fails or finds no match, no longer adds to the undo
"         buffer for recent vim 6.0 development versions.
"       - However, clears the last message when closing tags in normal mode
"   
"   * Changed the closetag_html_style variable to be buffer-local rather than
"     global.
"
"   * Expanded documentation

" Has this already been loaded?
if exists("loaded_closetag")
    finish
endif
let loaded_closetag=1

"------------------------------------------------------------------------------
" User configurable settings
"------------------------------------------------------------------------------

" if html, don't close certain tags.  Works best if ignorecase is set.
" otherwise, capitalize these elements according to your html editing style
if !exists("g:unaryTagsStack")
    if exists("g:closetag_html_style")
	let g:unaryTagsStack= "area base br col embed hr img input link meta param"
    else " for xsl and xsl
	let g:unaryTagsStack=""
    endif
endif

if !exists("g:closetag_fill_content")
    let g:closetag_fill_content = (v:version >= 700)
endif

"------------------------------------------------------------------------------
" Set up mappings for tag closing
"------------------------------------------------------------------------------
if v:version < 700
inoremap <C-_> <C-R>=<SID>GetCloseTag('i')<CR>
nmap <C-_> a<C-_><Esc>
else
inoremap <expr> <C-_> <SID>GetCloseTag('i')
nnoremap <expr> <C-_> <SID>GetCloseTag('n')
endif

"------------------------------------------------------------------------------
" Tag closer - uses the stringstack implementation below
"------------------------------------------------------------------------------

" Returns the most recent unclosed tag-name
" (ignores tags in the variable referenced by a:unaryTagsStack)
function! s:GetLastOpenTag(unaryTagsStack)
    " Search backwards through the file line by line using getline()
    " Overall strategy (moving backwards through the file from the cursor):
    "  Push closing tags onto a stack.
    "  On an opening tag, if the tag matches the stack top, discard both.
    "   -- if the tag doesn't match, signal an error.
    "   -- if the stack is empty, use this tag
    let linenum=line(".")
    let lineend=col(".") - 1 " start: cursor position
    let first=1              " flag for first line searched
    let b:TagStack=""        " main stack of tags
    let startInComment=s:InComment()

    let tagpat='</\=\(\k\|[-:]\)\+\|/>'
    " Search for: closing tags </tag, opening tags <tag, and unary tag ends />
    while (linenum>0)
	" Every time we see an end-tag, we push it on the stack.  When we see an
	" open tag, if the stack isn't empty, we pop it and see if they match.
	" If no, signal an error.
	" If yes, continue searching backwards.
	" If stack is empty, return this open tag as the one that needs closing.
	let line=getline(linenum)
	if first
	    let line=strpart(line,0,lineend)
	else
	    let lineend=strlen(line)
	endif
	let b:lineTagStack=""
	let mpos=0
	let b:TagCol=0
	" Search the current line in the forward direction, pushing any tags
	" onto a special stack for the current line
	while (mpos > -1)
	    let mpos=matchend(line,tagpat)
	    if mpos > -1
		let b:TagCol=b:TagCol+mpos
		let tag=matchstr(line,tagpat)
		
		if exists("b:closetag_disable_synID") || startInComment==s:InCommentAt(linenum, b:TagCol)
		    let b:TagLine=linenum
		    call s:Push(matchstr(tag,'[^<>]\+'),"b:lineTagStack")
		endif
		"echo "Tag: ".tag." ending at position ".mpos." in '".line."'."
		let lineend=lineend-mpos
		let line=strpart(line,mpos,lineend)
	    endif
	endwhile
	" Process the current line stack
	while (!s:EmptystackP("b:lineTagStack"))
	    let tag=s:Pop("b:lineTagStack")
	    if match(tag, "^/") == 0		"found end tag
		call s:Push(tag,"b:TagStack")
		"echo linenum." ".b:TagStack
	    elseif s:EmptystackP("b:TagStack") && !s:Instack(tag, a:unaryTagsStack)	"found unclosed tag
		return tag
	    else
		let endtag=s:Peekstack("b:TagStack")
		if endtag == "/".tag || endtag == "/"
		    call s:Pop("b:TagStack")	"found a open/close tag pair
		    "echo linenum." ".b:TagStack
		elseif !s:Instack(tag, a:unaryTagsStack) "we have a mismatch error
		    echohl ErrorMsg
		    echo "tag mismatch: <".tag."> doesn't match <".endtag.">.  (Line ".linenum." Tagstack: ".b:TagStack.")"
		    echohl None
		    return ""
		endif
	    endif
	endwhile
	let linenum=linenum-1 | let first=0
    endwhile
    " At this point, we have exhausted the file and not found any opening tag
    echohl WarningMsg
    echo "No opening tags."
    echohl None
    return ""
endfunction

if v:version >= 700
    let s:lastFillPos = []
endif
" Returns insert / normal mode commands to close the most recent unclosed tag. 
function! s:GetCloseTag(mode)
    let tagname = s:GetLastOpenTag((exists('b:unaryTagsStack') ? 'b:unaryTagsStack' : 'g:unaryTagsStack'))
    if tagname == ''
	return ''
    endif

    let tag = '</'.tagname.'>'
    if a:mode ==# 'i'
	if g:closetag_fill_content && getpos('.') == s:lastFillPos && tag ==# s:lastTag
	    " Command repeated at the last fill position; skip insert of
	    " contents and jump to end of tag. 
	    " Note: If the tag was closed in a new line, we first need to go to
	    " that line. We don't use the / command to avoid clobbing the search
	    " history. 
	    return "\<Esc>" . (line('.') == s:lastEndTagLine ? '' :  s:lastEndTagLine . 'G0') . 'f>a'
	endif

	return g:closetag_fill_content ? s:CheckForEmptyContent(tagname, tag) : tag
    elseif a:mode ==# 'n'
	" For normal mode, detect whether the cursor is on the beginning of a
	" tag, and insert / append accordingly. 
	let insertCmd = (matchstr(getline('.'), '\%' . col('.') . 'c.') ==# '<' ? 'i' : 'a')
	return insertCmd . tag . "\<Esc>"
    else
	throw 'ASSERT: Unsupported mode: ' . a:mode
    endif
endfunction

" return 1 if the cursor is in a syntactically identified comment field
" (fails for empty lines: always returns not-in-comment)
function! s:InComment()
    return synIDattr(synID(line("."), col("."), 0), "name") =~ 'Comment'
endfunction

" return 1 if the position specified is in a syntactically identified comment field
function! s:InCommentAt(line, col)
    return synIDattr(synID(a:line, a:col, 0), "name") =~ 'Comment'
endfunction

"------------------------------------------------------------------------------
" Movement inside empty tag. 
"------------------------------------------------------------------------------
function! s:CheckForEmptyContent(tagname, tag)
    let tagAndMovement = ''
    let [line, col, matchNum] = searchpos('<' . a:tagname . '\%(\_s\|\_s\_[^>]*[^/]\)\?>\%(\(\)\|\(\t\+\)\|\(\s\+\)\|\(\s*\n\_s*\)\)\%#', 'bcnpW')
    if matchNum == 0
	" No empty tag before cursor. 
	return a:tag
    elseif matchNum == 2
	" Empty tag directly before cursor. 
	let tagAndMovement = a:tag . repeat("\<Left>", strlen(a:tag))
    elseif matchNum == 3 || matchNum == 4
	" Empty tag and <Tab> / whitespace before cursor. 
	let tagAndMovement = (matchNum == 3 ? "\t" : ' ') . a:tag . repeat("\<Left>", strlen(a:tag) + 1)
    elseif matchNum == 5
	" Empty tag and newline before cursor. 
	let tagAndMovement = "$\n" . a:tag . "\<Up>\<End>\<BS>"
    else
	throw 'ASSERT: Invalid matchNum: ' . matchNum
    endif

    let s:lastFillPos = getpos('.')
    let s:lastTag = a:tag
    let s:lastEndTagLine = line('.') + (matchNum == 5 ? 1 : 0)

    return tagAndMovement
endfunction

"------------------------------------------------------------------------------
" String Stacks
"------------------------------------------------------------------------------
" These are strings of whitespace-separated elements, matched using the \< and
" \> patterns after setting the iskeyword option.
" 
" The sname argument should contain a symbolic reference to the stack variable
" on which method should operate on (i.e., sname should be a string containing
" a fully qualified (ie: g:, b:, etc) variable name.)

" Helper functions
function! s:SetKeywords()
    let s:IsKeywordBak=&iskeyword
    let &iskeyword="33-255"
endfunction

function! s:RestoreKeywords()
    let &iskeyword=s:IsKeywordBak
endfunction

" Push el onto the stack referenced by sname
function! s:Push(el, sname)
    if !s:EmptystackP(a:sname)
	exe "let ".a:sname."=a:el.' '.".a:sname
    else
	exe "let ".a:sname."=a:el"
    endif
endfunction

" Check whether the stack is empty
function! s:EmptystackP(sname)
    exe "let stack=".a:sname
    if match(stack,"^ *$") == 0
	return 1
    else
	return 0
    endif
endfunction

" Return 1 if el is in stack sname, else 0.
function! s:Instack(el, sname)
    exe "let stack=".a:sname
    call s:SetKeywords()
    let m=match(stack, "\\<".a:el."\\>")
    call s:RestoreKeywords()
    if m < 0
	return 0
    else
	return 1
    endif
endfunction

" Return the first element in the stack
function! s:Peekstack(sname)
    call s:SetKeywords()
    exe "let stack=".a:sname
    let top=matchstr(stack, "\\<.\\{-1,}\\>")
    call s:RestoreKeywords()
    return top
endfunction

" Remove and return the first element in the stack
function! s:Pop(sname)
    if s:EmptystackP(a:sname)
	echo "Error!  Stack ".a:sname." is empty and can't be popped."
	return ""
    endif
    exe "let stack=".a:sname
    " Find the first space, loc is 0-based.  Marks the end of 1st elt in stack.
    call s:SetKeywords()
    let loc=matchend(stack,"\\<.\\{-1,}\\>")
    exe "let ".a:sname."=strpart(stack, loc+1, strlen(stack))"
    let top=strpart(stack, match(stack, "\\<"), loc)
    call s:RestoreKeywords()
    return top
endfunction

function! s:Clearstack(sname)
    exe "let ".a:sname."=''"
endfunction
