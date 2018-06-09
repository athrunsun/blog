---
title: "Reusing Reducer Logic"
date: 2018/06/09 17:48
categories: Frontend
tags:
- React
- Redux
---
# Reference
* [Reusing Reducer Logic](https://redux.js.org/recipes/structuring-reducers/reusing-reducer-logic)
* [having multiple instance of same reusable redux react components on the same page/route](https://stackoverflow.com/questions/42906358/)

# The problem description
Say in a web app, we have a lot of data tables on different pages, every table has a pagination component.

How do we setup current page index and current page size for each table? At first thought we might want to setup action creators and reducers for each of the page with the same methods and state inside, just with different module names.

```javascript
// Action creator
const setPageIndex = pageIndex => ({
    type: 'SET_PAGE_INDEX',
    payload: pageIndex,
});

// Reducer
const createInitialState = () => ({
    pageIndex: 0,
});

const paginationReducer = (state = createInitialState(), action) => {
    switch (action.type) {
        case 'SET_PAGE_INDEX':
            return Object.assign({}, state, { pageIndex: action.payload });
        default:
            return state;
    }
};
```

But this way we'll get a lot of duplicate code!

# Namespace to the rescue
All these action creators and reducers share the same logic, just with different names, so in order to reuse the same logic, we should instead build action factory and reducer factory like the following.

Action creator `actions/paginationActions.js`:
```javascript
const ACTION_TYPES = {
    SET_PAGE_INDEX: 'SET_PAGE_INDEX',
};

const setPageIndexFactory = namespace => pageIndex => ({
    type: `${namespace}/${ACTION_TYPES.SET_PAGE_INDEX}`,
    payload: pageIndex,
});

const actionsFactory = namespace => ({
    setPageIndex: setPageIndexFactory(namespace),
});

export { ACTION_TYPES, actionsFactory };
```

Reducer `reducers/paginationReducer.js`:
```javascript
import { ACTION_TYPES } from 'actions/paginationActions';

const createInitialState = () => ({
    pageIndex: 0,
});

const paginationReducerFactory = namespace => (state = createInitialState(), action) => {
    switch (action.type) {
        case `${namespace}/${ACTION_TYPES.SET_PAGE_INDEX}`:
            return Object.assign({}, state, { pageIndex: action.payload });
        default:
            return state;
    }
};

export default paginationReducerFactory;
```

Say the namespace of one of our web pages is `DOCUMENT/DETAILS`, which is defined in `constants.js`:
```javascript
const NAMESPACE = {
    DOCUMENT_DETAILS: 'DOCUMENT/DETAILS',
};

export { NAMESPACE };
```

In our `reducers/index.js`, define rootReducer as the following:
```javascript
import { NAMESPACE } from 'constants';
import paginationReducerFactory from 'reducers/paginationReducer';

export default {
    [`pagination_${NAMESPACE.DOCUMENT_DETAILS}`]: paginationReducerFactory(NAMESPACE.DOCUMENT_DETAILS),
};
```

And here is how to use it in our components:
```javascript
import React, { Component } from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';

import { NAMESPACE } from 'constants';

import { actionsFactory as allPaginationActionsFactory } from 'actions/paginationActions';

const MODULE_NAMESPACE = NAMESPACE.DOCUMENT_DETAILS;

class DocumentDetails extends Component {
    render() {
        const { pageIndex, paginationActions } = this.props;

        return (
            <DataTable pageIndex={pageIndex} onPageIndexChangeHandler={paginationActions.setPageIndex} />
        );
    }
}

const mapStateToProps = state => ({
    pagination: state[`pagination_${MODULE_NAMESPACE}`],
});

const mapDispatchToProps = dispatch => ({
    paginationActions: bindActionCreators(allPaginationActionsFactory(MODULE_NAMESPACE), dispatch),
});

export default connect(mapStateToProps, mapDispatchToProps)(DocumentDetails);
```

# Make it more universal
Say our data table component is universal, here is how to define it in a universal way:
```javascript
import React, { Component } from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';

import { actionsFactory as allPaginationActionsFactory } from 'actions/paginationActions';

class CommonDataTable extends Component {
    render() {
        const { pageIndex, paginationActions } = this.props;

        return (
            ...
        );
    }
}

const mapStateToProps = (state, ownProps) => ({
    pagination: state[`pagination_${ownProps.namespace}`],
});

const mapDispatchToProps = (dispatch, ownProps) => ({
    paginationActions: bindActionCreators(allPaginationActionsFactory(ownProps.namespace), dispatch),
});

export default connect(mapStateToProps, mapDispatchToProps)(CommonDataTable);
```

So in our `DocumentDetails` page we shall use it like this:
```javascript
import { NAMESPACE } from 'constants';

const MODULE_NAMESPACE = NAMESPACE.DOCUMENT_DETAILS;

class DocumentDetails extends Component {
    render() {
        return (
            <CommonDataTable namespace={MODULE_NAMESPACE} />
        );
    }
}
```

# Summary
Official Redux documentation express a different way but I feel the above approach is more comprehensive to me.

At last, reusing reducer logic is IMPORTANT simply because "DO NOT REPEAT YOURSELF" is IMPORTANT.
