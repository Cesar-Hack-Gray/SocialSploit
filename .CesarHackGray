#!/usr/bin/python

import sys


class BashFileIterator:
    class _Delimiter(object):
        def __init__(self, character, _type=''):
            self.character = character
            # type may be 'AP' or 'AS' (Arithmetic Expansion delimited by (()) or [] respectively),
            #             'S' (Command Substitution) or 'P' (Parameter Expansion)
            # type is set only for parenthesis or curly brace and square brace that opens group
            # e.g. in this statement $((1+2)) only the 1st '(' will have type ('AP')
            self.type = _type

        def is_group_opening(self):
            return bool(self.type or self.character in ("'", '"', '`'))

        def __eq__(self, other):
            if isinstance(other, BashFileIterator._Delimiter):
                return other.character == self.character
            elif isinstance(other, basestring):
                return other == self.character
            return False

        def __ne__(self, other):
            return not self.__eq__(other)

        def __str__(self):
            return self.character

        __repr__ = __str__

    def __init__(self, src):
        self.src = src
        self.reset()

    def reset(self):
        self.pos = 0
        self.insideComment = False
        self.insideHereDoc = False

        # possible characters in stack:
        # (, ) -- means Arithmetic Expansion or Command Substitution
        # {, } -- means Parameter Expansion
        # [, ] -- means Arithmetic Expansion
        # ` -- means Command Substitution
        # ' -- means single-quoted string
        # " -- means double-quoted string
        self._delimiters_stack = []
        self._indices_of_escaped_characters = set()

    def getLastGroupOpeningDelimiter(self):
        return next((d for d in reversed(self._delimiters_stack) if d.is_group_opening()),
                    BashFileIterator._Delimiter(''))

    def pushDelimiter(self, character, _type=''):
        d = BashFileIterator._Delimiter(character, _type=_type)
        last_opening = self.getLastGroupOpeningDelimiter()
        last = self._delimiters_stack[-1] if len(self._delimiters_stack) > 0 else BashFileIterator._Delimiter('')

        if d in ('{', '}'):
            if _type != '':  # delimiter that opens group
                self._delimiters_stack.append(d)
            elif d == '}' and last == '{':
                self._delimiters_stack.pop()
        elif d in ('(', ')'):
            if _type != '':  # delimiter that opens group
                self._delimiters_stack.append(d)
            elif last_opening == '(':
                if last == '(' and d == ')':
                    self._delimiters_stack.pop()
                else:
                    self._delimiters_stack.append(d)
        elif d in ('[', ']'):
            if _type != '':  # delimiter that opens group
                self._delimiters_stack.append(d)
            elif last_opening == '[':
                if last == '[' and d == ']':
                    self._delimiters_stack.pop()
                else:
                    self._delimiters_stack.append(d)
        elif d == "'" and last_opening != '"' or d == '"' and last_opening != "'" or d == '`':
            if d == last_opening:
                self._delimiters_stack.pop()
            else:
                self._delimiters_stack.append(d)

    def isInsideGroup(self):
        return len(self._delimiters_stack) != 0

    def getPreviousCharacters(self, n, should_not_start_with_escaped=True):
        """
        'should_not_start_with_escaped' means return empty string if the first character is escaped 
        """
        first_character_index = max(0, self.pos - n)
        if first_character_index in self._indices_of_escaped_characters:
            return ''
        else:
            return self.src[max(0, self.pos - n):self.pos]

    def getPreviousCharacter(self, should_not_start_with_escaped=True):
        return self.getPreviousCharacters(1, should_not_start_with_escaped=should_not_start_with_escaped)

    def getNextCharacters(self, n):
        return self.src[self.pos + 1:self.pos + n + 1]

    def getNextCharacter(self):
        return self.getNextCharacters(1)

    def getPreviousWord(self):
        word = ''
        i = 1
        while i <= self.pos:
            newWord = self.getPreviousCharacters(i)
            if not newWord.isalpha():
                break
            word = newWord
            i += 1
        return word

    def getNextWord(self):
        word = ''
        i = 1
        while self.pos + i < len(self.src):
            newWord = self.getNextCharacters(i)
            if not newWord.isalpha():
                break
            word = newWord
            i += 1
        return word

    def getPartOfLineAfterPos(self, skip=0):
        result = ''
        i = self.pos + 1 + skip
        while i < len(self.src) and self.src[i] != '\n':
            result += self.src[i]
            i += 1
        return result

    def getPartOfLineBeforePos(self, skip=0):
        result = ''
        i = self.pos - 1 - skip
        while i >= 0 and self.src[i] != '\n':
            result = self.src[i] + result
            i -= 1
        return result

    def charactersGenerator(self):
        hereDocWord = ''
        _yieldNextNCharactersAsIs = 0

        def close_heredoc():
            self.insideHereDoc = False

        callbacks_after_yield = []

        while self.pos < len(self.src):
            ch = self.src[self.pos]

            if _yieldNextNCharactersAsIs > 0:
                _yieldNextNCharactersAsIs -= 1
            elif ch == "\\" and not self.isEscaped():
                self._indices_of_escaped_characters.add(self.pos + 1)
            else:
                if ch == "\n" and not self.isInsideSingleQuotedString() and not self.isInsideDoubleQuotedString():
                    # handle end of comments and heredocs
                    if self.insideComment:
                        self.insideComment = False
                    elif self.insideHereDoc and self.getPartOfLineBeforePos() == hereDocWord:
                        callbacks_after_yield.append(close_heredoc)
                elif not self.isInsideComment() and not self.isInsideHereDoc():
                    if ch in ('"', "'"):
                        # single quote can't be escaped inside single-quoted string
                        if not self.isEscaped() or ch == "'" and self.isInsideSingleQuotedString():
                            self.pushDelimiter(ch)
                    elif not self.isInsideSingleQuotedString():
                        if not self.isEscaped():
                            if ch == "#" and not self.isInsideGroup() and \
                                    (self.getPreviousCharacter() in ('\n', '\t', ' ', ';') or self.pos == 0):
                                # handle comments
                                self.insideComment = True
                            elif ch == '`':
                                self.pushDelimiter(ch)
                            elif ch == '$':
                                next_char = self.getNextCharacter()
                                if next_char in ('{', '(', '['):
                                    next_2_chars = self.getNextCharacters(2)
                                    _type = 'AP' if next_2_chars == '((' else {'{': 'P', '(': 'S', '[': 'AS'}[next_char]
                                    self.pushDelimiter(next_char, _type=_type)
                                    _yieldNextNCharactersAsIs = 1
                            elif ch in ('{', '}', '(', ')', '[', ']'):
                                self.pushDelimiter(ch)
                            elif ch == '<' and self.getNextCharacter() == '<' and not self.isInsideGroup():
                                _yieldNextNCharactersAsIs = 1

                                # we should handle correctly heredocs and herestrings like this one:
                                # echo <<< one

                                if self.getNextCharacters(2) != '<<':
                                    # heredoc
                                    self.insideHereDoc = True
                                    hereDocWord = self.getPartOfLineAfterPos(skip=1)
                                    if hereDocWord[0] == '-':
                                        hereDocWord = hereDocWord[1:]
                                    hereDocWord = hereDocWord.strip().replace('"', '').replace("'", '')

            yield ch

            while len(callbacks_after_yield) > 0:
                callbacks_after_yield.pop()()

            self.pos += 1

        assert not self.isInsideGroup(), 'Invalid syntax'
        raise StopIteration

    def isEscaped(self):
        return self.pos in self._indices_of_escaped_characters

    def isInsideDoubleQuotedString(self):
        return self.getLastGroupOpeningDelimiter() == '"'

    def isInsideSingleQuotedString(self):
        return self.getLastGroupOpeningDelimiter() == "'"

    def isInsideComment(self):
        return self.insideComment

    def isInsideHereDoc(self):
        return self.insideHereDoc

    def isInsideParameterExpansion(self):
        return self.getLastGroupOpeningDelimiter() == '{'

    def isInsideArithmeticExpansion(self):
        return self.getLastGroupOpeningDelimiter().type in ('AP', 'AS')

    def isInsideCommandSubstitution(self):
        last_opening_delimiter = self.getLastGroupOpeningDelimiter()
        return last_opening_delimiter == '`' or last_opening_delimiter.type == 'S'

    def isInsideAnything(self):
        return self.isInsideGroup() or self.insideHereDoc or self.insideComment

    def isInsideGroupWhereWhitespacesCannotBeTruncated(self):
        return self.isInsideComment() or self.isInsideDoubleQuotedString() or self.isInsideDoubleQuotedString() or \
               self.isInsideHereDoc() or self.isInsideParameterExpansion()


def minify(src):
    # first: remove all comments
    it = BashFileIterator(src)
    src = ""  # result
    for ch in it.charactersGenerator():
        if not it.isInsideComment():
            src += ch

    # secondly: remove empty strings, strip lines and truncate spaces (replace groups of whitespaces by single space)
    it = BashFileIterator(src)
    src = ""  # result
    emptyLine = True  # means that no characters has been printed in current line so far
    previousSpacePrinted = True
    for ch in it.charactersGenerator():
        if it.isInsideSingleQuotedString():
            # first of all check single quoted string because line continuation does not work inside
            src += ch
        elif ch == "\\" and not it.isEscaped() and it.getNextCharacter() == "\n":
            # then check line continuation
            # line continuation will occur on the next iteration. just skip this backslash
            continue
        elif ch == "\n" and it.isEscaped():
            # line continuation occurred
            # backslash at the very end of line means line continuation
            # so remove previous backslash and skip current newline character ch
            continue
        elif it.isInsideGroupWhereWhitespacesCannotBeTruncated() or it.isEscaped():
            src += ch
        elif ch in (' ', '\t') and not previousSpacePrinted and not emptyLine and \
                not it.getNextCharacter() in (' ', '\t', '\n'):
            src += " "
            previousSpacePrinted = True
        elif ch == "\n" and it.getPreviousCharacter() != "\n" and not emptyLine:
            src += ch
            previousSpacePrinted = True
            emptyLine = True
        elif ch not in (' ', '\t', '\n'):
            src += ch
            previousSpacePrinted = False
            emptyLine = False

    # thirdly: get rid of newlines
    it = BashFileIterator(src)
    src = ""  # result
    for ch in it.charactersGenerator():
        if it.isInsideAnything() or ch != "\n":
            src += ch
        else:
            prevWord = it.getPreviousWord()
            nextWord = it.getNextWord()
            if it.getNextCharacter() == '{':  # functions declaration, see test t8.sh
                if it.getPreviousCharacter() == ')':
                    continue
                else:
                    src += ' '
            elif prevWord in ("until", "while", "then", "do", "else", "in", "elif", "if") or \
                            nextWord in ("in",) or \
                            it.getPreviousCharacter() in ("{", "(") or \
                            it.getPreviousCharacters(2) in ("&&", "||"):
                src += " "
            elif nextWord in ("esac",) and it.getPreviousCharacters(2) != ';;':
                if it.getPreviousCharacter() == ';':
                    src += ';'
                else:
                    src += ';;'
            elif it.getNextCharacter() != "" and it.getPreviousCharacter() not in (";", '|'):
                src += ";"

    # finally: remove spaces around semicolons and pipes and other delimiters
    it = BashFileIterator(src)
    src = ""  # result
    other_delimiters = ('|', '&', ';', '<', '>', '(', ')')  # characters that may not be surrounded by whitespaces
    for ch in it.charactersGenerator():
        if it.isInsideGroupWhereWhitespacesCannotBeTruncated():
            src += ch
        elif ch in (' ', '\t') \
                and (it.getPreviousCharacter() in other_delimiters or
                             it.getNextCharacter() in other_delimiters) \
                and it.getNextCharacters(2) not in ('<(', '>('):  # process substitution
                                                                    # see test t_process_substitution.sh for details
            continue
        else:
            src += ch

    return src


if __name__ == "__main__":
    # https://www.gnu.org/software/bash/manual/html_node/Reserved-Word-Index.html
    # http://pubs.opengroup.org/onlinepubs/009695399/utilities/xcu_chap02.html
    # http://pubs.opengroup.org/onlinepubs/9699919799/

    # get bash source from file or from stdin
    src = ""
    if len(sys.argv) > 1:
        with open(sys.argv[1], "r") as ifile:
            src = ifile.read()
    else:
        src = sys.stdin.read()
    # use stdout.write instead of print to avoid newline at the end (print with comma at the end does not work)
    sys.stdout.write(minify(src))


# important rules:
# 1. A single-quote cannot occur within single-quotes.
# 2. The input characters within the double-quoted string that are also enclosed between "$(" and the matching ')'
#    shall not be affected by the double-quotes, but rather shall define that command whose output replaces the "$(...)"
#    when the word is expanded.
# 3. Within the double-quoted string of characters from an enclosed "${" to the matching '}', an even number of
#    unescaped double-quotes or single-quotes, if any, shall occur. A preceding <backslash> character shall be used
#    to escape a literal '{' or '}'
# 4.
