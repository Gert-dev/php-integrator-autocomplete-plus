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

        suggestions = @findSuggestionsForPrefix(variables, prefix.trim())

        return new Promise (resolve, reject) =>
            resolve(suggestions)


    ###*
     * Returns suggestions available matching the given prefix.
     *
     * @param {array}  variables
     * @param {string} prefix
     *
     * @return array
    ###
    findSuggestionsForPrefix: (variables, prefix) ->
        variables = fuzzaldrin.filter(variables, prefix, key: 'name')

        suggestions = []

        for variable in variables
            type = null

            # Just show the last part of a class name with a namespace.
            if variable.type
                parts = variable.type.split('\\')
                type = parts.pop()

            suggestions.push
                type              : 'variable'
                text              : variable.name
                leftLabel         : type
                replacementPrefix : prefix

        return suggestions
