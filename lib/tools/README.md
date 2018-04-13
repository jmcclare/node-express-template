# Tools #

This is a collection of tools and language extensions that didn't merit their
own modules.


## clone ##

Based on a [Stack Overflow
answer](http://stackoverflow.com/questions/728360/most-elegant-way-to-clone-a-javascript-object/728694#728694).
This copies the full hierarchy of an object so long as it only contains
properties of plain Object, Array, Date, String, Number, or Boolean.

As the Stack Overflow answer states, it will make copies of referenced
variables instead of cloning the references themselves. If a property is a
reference to its parent object, clone will get stuck in an infinite loop.

Usage:

    clone = require('tools').clone

    oldObj = { someParam: 'a string' }
    newObj = clone oldObj


## merge ##

`merge` merges the whole hierarchy of an object into another object,
overwriting any matching properties.

Parameters:

    updates - obj, object to merge into base
    base - obj, object to have updates merged into. This will be modified.

Returns the newly modifed base.

`updates` has the same restrictions as objects cloned by `clone`. `base` can be
any kind of object, including a `Date`.

For example:

    merge = require('tools').merge

    baseObj = { someParam: 'a string', someOtherParam: 'another string' }
    updateObj =
        someParam: 'a different string'
        updateParam: 'string from update'

    # Merge updateObj into baseObj
    merge updateObj baseObj

    # baseObj will be:
    #
    # {
    #     someParam: 'a different string',
    #     someOtherParam: 'another string',
    #     updateParam: 'string from update'
    # }
