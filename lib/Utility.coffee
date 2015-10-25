
module.exports =
    ###*
     * Regular expression that will search for a structure (class, interface, trait, ...).
    ###
    structureStartRegex : /(?:abstract class|class|trait|interface)\s+(\w+)/

    ###*
     * Regular expression that will search for a use statement.
    ###
    useStatementRegex   : /(?:use)(?:[^\w\\])([\w\\]+)(?![\w\\])(?:(?:[ ]+as[ ]+)(\w+))?(?:;)/

    ###*
     * Add the use for the given class if not already added.
     *
     * @param {TextEditor} editor                  Atom text editor.
     * @param {string}     className               Name of the class to add.
     * @param {boolean}    allowAdditionalNewlines Whether to allow adding additional newlines to attempt to group use
     *                                             statements.
     *
     * @return {number} The amount of lines added (including newlines), so you can reliably and easily offset your rows.
     #                  This could be zero if a use statement was already present.
    ###
    addUseClass: (editor, className, allowAdditionalNewlines) ->
        if className.split('\\').length == 1 or className.indexOf('\\') == 0
            return null

        bestUse = 0
        bestScore = 0
        placeBelow = true
        doNewLine = true
        lineCount = editor.getLineCount()

        # Determine an appropriate location to place the use statement.
        for i in [0 .. lineCount - 1]
            line = editor.lineTextForBufferRow(i).trim()

            if line.length == 0
                continue

            scopeDescriptor = editor.scopeDescriptorForBufferPosition([i, line.length]).getScopeChain()

            if scopeDescriptor.indexOf('.comment') >= 0
                continue

            if line.match(@structureStartRegex)
                break

            if line.indexOf('namespace ') >= 0
                bestUse = i

            matches = @useStatementRegex.exec(line)

            if matches? and matches[1]?
                if matches[1] == className
                    return 0

                score = @scoreClassName(className, matches[1])

                if score >= bestScore
                    bestUse = i
                    bestScore = score

                    if @doShareCommonNamespacePrefix(className, matches[1])
                        doNewLine = false
                        placeBelow = if className.length >= matches[1].length then true else false

                    else
                        doNewLine = true
                        placeBelow = true

        # Insert the use statement itself.
        lineEnding = editor.getBuffer().lineEndingForRow(0)

        if not allowAdditionalNewlines
            doNewLine = false

        if not lineEnding
            lineEnding = "\n"

        textToInsert = ''

        if doNewLine and placeBelow
            textToInsert += lineEnding

        textToInsert += "use #{className};" + lineEnding

        if doNewLine and not placeBelow
            textToInsert += lineEnding

        lineToInsertAt = bestUse + (if placeBelow then 1 else 0)
        editor.setTextInBufferRange([[lineToInsertAt, 0], [lineToInsertAt, 0]], textToInsert)

        return (1 + (if doNewLine then 1 else 0))

    ###*
     * Returns a boolean indicating if the specified class names share a common namespace prefix.
     *
     * @param {string} firstClassName
     * @param {string} secondClassName
     *
     * @return {boolean}
    ###
    doShareCommonNamespacePrefix: (firstClassName, secondClassName) ->
        firstClassNameParts = firstClassName.split('\\')
        secondClassNameParts = secondClassName.split('\\')

        firstClassNameParts.pop()
        secondClassNameParts.pop()

        return if firstClassNameParts.join('\\') == secondClassNameParts.join('\\') then true else false

    ###*
     * Scores the first class name against the second, indicating how much they 'match' each other. This can be used
     * to e.g. find an appropriate location to place a class in an existing list of classes.
     *
     * @param {string} firstClassName
     * @param {string} secondClassName
     *
     * @return {float}
    ###
    scoreClassName: (firstClassName, secondClassName) ->
        firstClassNameParts = firstClassName.split('\\')
        secondClassNameParts = secondClassName.split('\\')

        maxLength = 0

        if firstClassNameParts.length > secondClassNameParts.length
            maxLength = secondClassNameParts.length

        else
            maxLength = firstClassNameParts.length

        totalScore = 0

        # NOTE: We don't score the last part.
        for i in [0 .. maxLength - 2]
            if firstClassNameParts[i] == secondClassNameParts[i]
                totalScore += 2

        if @doShareCommonNamespacePrefix(firstClassName, secondClassName)
            if firstClassName.length == secondClassName.length
                totalScore += 2

            else
                # Stick closer to items that are smaller in length than items that are larger in length.
                totalScore -= 0.001 * Math.abs(secondClassName.length - firstClassName.length)

        return totalScore
