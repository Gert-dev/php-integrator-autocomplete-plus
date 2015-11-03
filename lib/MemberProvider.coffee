fuzzaldrin = require 'fuzzaldrin'

AbstractProvider = require "./AbstractProvider"

module.exports =

##*
# Provides autocompletion for members of variables such as after ->, ::.
##
class MemberProvider extends AbstractProvider
    ###*
     * @inheritdoc
     *
     * Autocompletion for class members, i.e. after a ::, ->, ...
    ###
    regex: /(?:(?:[a-zA-Z0-9_]*)\s*(?:\(.*\))?\s*(?:->|::)\s*)+([a-zA-Z0-9_]*)/g

    ###*
     * @inheritdoc
    ###
    getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
        prefix = @getPrefix(editor, bufferPosition)
        return [] unless prefix.length

        className = @service.getCalledClass(editor, bufferPosition)
        return [] unless className

        # We only autocomplete after splitters, so there must be at least one word, one splitter, and another word
        # (the latter which could be empty).
        elements = prefix.split(/(->|::)/)
        return [] unless elements.length > 2

        callback = (currentClassInfo) =>
            currentClassParents = []

            if currentClassInfo
                currentClassParents = currentClassInfo.parents

            mustBeStatic = false

            if elements[elements.length - 2] == '::' and elements[elements.length - 3].trim() != 'parent'
                mustBeStatic = true

            characterAfterPrefix = editor.getTextInRange([bufferPosition, [bufferPosition.row, bufferPosition.column + 1]])
            insertParameterList = if characterAfterPrefix == '(' then false else true

            return @findSuggestionsForPrefix(className, elements[elements.length-1].trim(), (element) =>
                # See also atom-autocomplete-php ticket #127.
                return false if mustBeStatic and not element.isStatic
                return false if element.isPrivate and element.declaringClass.name != currentClass
                return false if element.isProtected and element.declaringClass.name != currentClass and element.declaringClass.name not in currentClassParents

                # Constants are only available when statically accessed.
                return false if not element.isMethod and not element.isProperty and not mustBeStatic

                return true
            , insertParameterList)

        currentClass = @service.determineFullClassName(editor)

        if not currentClass
            # There is no need to load the current class' information, return results immediately.
            return callback(null)

        else
            # We need to fetch information about the current class, do it asynchronously (using promises).
            return @service.getClassInfo(currentClass, true).then(callback)

    ###*
     * Returns suggestions available matching the given prefix.
     *
     * @param {string}   className           The name of the class to show members of.
     * @param {string}   prefix              Prefix to match (may be left empty to list all members).
     * @param {callback} filterCallback      A callback that should return true if the item should be added to the
     *                                       suggestions list.
     * @param {bool}     insertParameterList Whether to insert a list of parameters for methods.
     *
     * @return {array}
    ###
    findSuggestionsForPrefix: (className, prefix, filterCallback, insertParameterList = true) ->
        classInfo = @service.getClassInfo(className)

        return [] if not classInfo

        members = [];

        # Ensure we have one big pool so we can optimally match using fuzzaldrin.
        members.push(obj) for name,obj of classInfo.methods
        members.push(obj) for name,obj of classInfo.constants
        members.push(obj) for name,obj of classInfo.properties

        matches = fuzzaldrin.filter(members, prefix, key: 'name')

        suggestions = []

        for match in matches
            if filterCallback and not filterCallback(match)
                continue

            # Ensure we don't get very long return types by just showing the last part.
            snippet = null
            displayText = match.name
            returnValueParts = if match.args.return?.type then match.args.return.type.split('\\') else []
            returnValue = returnValueParts[returnValueParts.length - 1]

            if match.isMethod
                type = 'method'
                snippet = if insertParameterList then @getFunctionSnippet(match.name, match.args) else null
                displayText = @getFunctionSignature(match.name, match.args)

            else if match.isProperty
                type = 'property'

            else
                type = 'constant'

            suggestions.push
                text        : match.name,
                type        : type
                snippet     : snippet
                displayText : displayText
                leftLabel   : returnValue
                description : if match.args.descriptions.short? then match.args.descriptions.short else ''
                className   : if match.args.deprecated then 'php-integrator-autocomplete-plus-strike' else ''

        return suggestions
