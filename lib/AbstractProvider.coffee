{TextEditor} = require 'atom'

module.exports =

##*
# Base class for providers.
##
class AbstractProvider
    ###*
     * The regular expression that is used for the prefix.
    ###
    regex: ''

    ###*
     * The class selectors for which autocompletion triggers.
    ###
    selector: '.source.php'

    ###*
     * The inclusion priority of the provider.
    ###
    inclusionPriority: 1

    ###*
     * The class selectors autocompletion is explicitly disabled for (overrules the {@see selector}).
    ###
    disableForSelector: '.source.php .comment, .source.php .string'

    ###*
     * The service (that can be used to query the source code and contains utility methods).
    ###
    service: null

    ###*
     * Contains global package settings.
    ###
    config: null

    ###*
     * Constructor.
     *
     * @param {Config} config
    ###
    constructor: (@config) ->
        @excludeLowerPriority = @config.get('disableBuiltinAutocompletion')

        @config.onDidChange 'disableBuiltinAutocompletion', (newValue) =>
            @excludeLowerPriority = newValue

    ###*
     * Initializes this provider.
     *
     * @param {mixed} service
    ###
    activate: (@service) ->

    ###*
     * Deactives the provider.
    ###
    deactivate: () ->

    ###*
     * Entry point for all requests from autocomplete-plus.
     *
     * @param {TextEditor} editor
     * @param {Point}      bufferPosition
     * @param {string}     scopeDescriptor
     * @param {string}     prefix
     *
     * @return {Promise|array}
    ###
    getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
        throw new Error("This method is abstract and must be implemented!")

    ###*
     * Builds the snippet for a PHP function or method.
     *
     * @param {string} name The name of the function or method.
     * @param {array}  info Information about the function or method.
     *
     * @return {string}
    ###
    getFunctionSnippet: (name, info) ->
        body = name + "("

        isInOptionalList = false

        for param, index in info.parameters
            description = ''
            description += '${' + (index + 1) + ':[' if param.isOptional and not isInOptionalList
            description += ', '  if index != 0
            description += '&'   if param.isReference
            description += '$' + param.name
            description += '...' if param.isVariadic
            description += ']}'   if param.isOptional and index == (info.parameters.length - 1)

            isInOptionalList = param.isOptional

            if not param.isOptional
                body += '${' + (index + 1) + ':' + description + '}'

            else
                body += description

        body += ")"

        # Ensure the user ends up after the inserted text when he's done cycling through the parameters with tab.
        body += "$0"

        return body

    ###*
     * Builds the signature for a PHP function or method.
     *
     * @param {string} word     The name of the function or method.
     * @param {array}  elements The (optional and required) parameters.
     *
     * @return {string}
    ###
    getFunctionSignature: (word, element) ->
        snippet = @getFunctionSnippet(word, element)

        # Just strip out the placeholders.
        signature = snippet.replace(/\$\{\d+:([^\}]+)\}/g, '$1')

        return signature[0 .. -3]

    ###*
     * Retrieves the short name for the specified class name (i.e. the last segment, without the class namespace).
     *
     * @param {string} className
     *
     * @return {string}
    ###
    getClassShortName: (className) ->
        return null if not className

        parts = className.split('\\')
        return parts.pop()

    ###*
     * Retrieves the prefix using the specified buffer position and the current class' configured regular expression.
     *
     * @param {TextEditor} editor
     * @param {Point}      bufferPosition
     *
     * @return {string}
    ###
    getPrefix: (editor, bufferPosition) ->
        # Unfortunately the regex $ doesn't seem to match the end when using backwardsScanInRange, so we match the regex
        # manually.
        line = editor.getBuffer().getTextInRange([[bufferPosition.row, 0], bufferPosition])

        matches = @regex.exec(line)

        if matches
            # We always want the last match, as that's closest to the cursor itself.
            return matches[matches.length - 1]

        return ''
