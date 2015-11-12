{Disposable} = require 'atom'

AtomConfig       = require './AtomConfig'
ClassProvider    = require './ClassProvider'
MemberProvider   = require './MemberProvider'
ConstantProvider = require './ConstantProvider'
VariableProvider = require './VariableProvider'
FunctionProvider = require './FunctionProvider'

module.exports =
    ###*
     * Configuration settings.
    ###
    config:
        disableBuiltinAutocompletion:
            title       : 'Disable built-in PHP autocompletion from Atom.'
            description : 'Atom also provides some default autocompletion for PHP, which includes function names for
                           some common PHP functions, but without their parameters (just their names). If this is
                           checked, these will be surpressed and not show up in autocompletion. If you uncheck this,
                           function names may show up twice: once from this package and once from Atom itself.'
            type        : 'boolean'
            default     : true
            order       : 1

        insertNewlinesForUseStatements:
            title       : 'Insert newlines for use statements'
            description : 'When enabled, the plugin will add additional newlines before or after an automatically added
                           use statement when it can\'t add them nicely to an existing group. This results in more
                           cleanly separated use statements but will create additional vertical whitespace.'
            type        : 'boolean'
            default     : false
            order       : 2

    ###*
     * The name of the package.
    ###
    packageName: 'php-integrator-autocomplete-plus'

    ###*
     * The configuration object.
    ###
    configuration: null

    ###*
     * List of tooltip providers.
    ###
    providers: []

    ###*
     * Activates the package.
    ###
    activate: ->
        @configuration = new AtomConfig(@packageName)

        @providers.push(new ConstantProvider(@configuration))
        @providers.push(new VariableProvider(@configuration))
        @providers.push(new FunctionProvider(@configuration))
        @providers.push(new ClassProvider(@configuration))
        @providers.push(new MemberProvider(@configuration))

    ###*
     * Deactivates the package.
    ###
    deactivate: ->
        @deactivateProviders()

    ###*
     * Activates the providers using the specified service.
    ###
    activateProviders: (service) ->
        for provider in @providers
            provider.activate(service)

    ###*
     * Deactivates any active providers.
    ###
    deactivateProviders: () ->
        for provider in @providers
            provider.deactivate()

        @providers = []

    ###*
     * Sets the php-integrator service.
     *
     * @param {mixed} service
     *
     * @return {Disposable}
    ###
    setService: (service) ->
        @activateProviders(service)

        return new Disposable => @deactivateProviders()

    ###*
     * Retrieves a list of supported autocompletion providers.
     *
     * @return {array}
    ###
    getProviders: ->
        return @providers
