## 0.2.0
### Features and enhancements
* Autocompletion now works inside double quoted strings `[1]`.
* When autocompleting variable names, their type is now displayed, if possible.
* Where possible, autocompletion is now asynchronous (using promises), improving performance.
* The right label of class members in the autocompletion window will now display the originating structure (i.e. class, interface or trait).
* The way use statements are added and class names are completed was drastically improved.
  * Multiple cursors are now properly supported.
  * The appropriate namespace will now be added if you are trying to do a relative import:

```php
<?php

// Select My\Foo\FooClass as suggestion.
Foo\FooClass

// The result (before):
use My\Foo\FooClass;

FooClass

// The result (after):
use My\Foo;

Foo\FooClass
```

`[1]` This might also complete in a few rare erroneous cases as well (e.g. `{SomeClass::test}` instead of `{${SomeClass::test}}`), but it's better to have autocompletion for common used cases and in a few rare erroneous cases than no autocompletion at all.

### Bugs fixed
* Autocompletion of class names inside comments will now no longer work.
* Class autocompletion will now work when the cursor is at the start of a line.
* Restrictions for function and constant autocompletion is now more relaxed. You will now receive autocompletion after `if (!` for built-in PHP functions and constants.

## 0.1.0
* Initial release.
