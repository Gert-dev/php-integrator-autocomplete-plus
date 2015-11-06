fuzzaldrin = require 'fuzzaldrin'

AbstractProvider = require "./AbstractProvider"

module.exports =

##*
# Provides autocompletion for local variable names.
##
class VariableProvider extends AbstractProvider
    ###*
     * @inheritdoc
     *
     * Variables are allowed inside double quoted strings (see also
     * {@link https://secure.php.net/manual/en/language.types.string.php#language.types.string.parsing}).
    ###
    disableForSelector: '.source.php .comment, .source.php .string.quoted.single'

    ###*
     * @inheritdoc
     *
     * "new" keyword or word starting with capital letter
    ###
    regex: /(\$[a-zA-Z_]*)/g

    ###*
     * @inheritdoc
    ###
    getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
        prefix = @getPrefix(editor, bufferPosition)
        return [] unless prefix.length

        variables = @service.getAvailableVariables(editor, bufferPosition)
        return [] unless variables.length

        return @findSuggestionsForPrefix(variables, prefix.trim())


    ###*
     * Returns suggestions available matching the given prefix.
     *
     * @param {array}  variables
     * @param {string} prefix
     *
     * @return array
    ###
    findSuggestionsForPrefix: (variables, prefix) ->
        matches = fuzzaldrin.filter(variables, prefix, key: 'name')

        suggestions = []

        for match in matches
            type = null

            # Just show the last part of a class name with a namespace.
            if match.type
                parts = match.type.split('\\')
                type = parts.pop()

            suggestions.push
                type              : 'variable'
                text              : match.name
                leftLabel         : type
                replacementPrefix : prefix

        return suggestions
