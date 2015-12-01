{apply, invoker, map, partialRight, pipeP, prop, sortBy, tap, trim} = R

{a, button, div, footer, header, h1, label, li, option, select, span, ul} = React.DOM

PT = React.PropTypes


# linkSelector : String
linkSelector =
  '#mega_main_menu .mega_dropdown>.menu-item:not(.menu-item-has-children)>.item_link'


# domParser : DOMParser
domParser = new DOMParser


# domFromHtmlStr : String -> HTMLDocument
domFromHtmlStr = :domFromHtmlStr (str) ->
  domParser.parseFromString str, "text/html"


# only does happy path at the moment
# fetchDomCorsFromUrl : String -> (HTMLDocument -> ())
fetchCorsDomFromUrl = :fetchDomFromUrl (url) ~>
  corsUrl = "https://crossorigin.me/" + url
  (...pipeline) ~>
    apply(pipeP, [(partialRight fetch, [{mode: "cors"}]), (invoker 0, "text"), domFromHtmlStr].concat(pipeline))(corsUrl)


# ShowListItem : ReactClass
ShowListItem = React.createClass {
  display: "ShowListItem"

  propTypes: {
    data : PT.objectOf(PT.string)
  }

  getInitialState: :getIntialState ->
    {
      isLoading: false
    }

  fetchStream: :fetchStream (e) ->
    e.preventDefault!
    e.target.blur!
    @setState {isLoading: true}
    fetchCorsDomFromUrl(@props.data.url)(
      ((dom) -> dom.querySelector ".flowplayer video>source[src*=rtmp]"),
      (prop "src"),
      ((src) ~>
        @setState {isLoading: false}
        if src then window.open src, "_self")
    )

  render: :render ->
    li {className: "asl-list-item"}, [
      a {className: "asl-list-link", href: @props.data.url, target: "_blank", onClick: @fetchStream}, [
        span null, @props.data.title
        if @state.isLoading then span {className: "asl-list-item-spinner"}, "❋"
      ]
    ]
}


# ShowList : ReactClass
ShowList = React.createClass {
  displayName: "ShowList"

  propTypes: {
    shows : PT.objectOf PT.string
  }

  getInitialState: :getInitialState ->
    {
      loadingState    : 0
      settingsVisible : false
      showData        : {}
    }

  componentDidMount: :componentDidMount ->
    storedTheme = window.localStorage.getItem "asl-color-theme"
    if storedTheme then @setState {colorTheme: storedTheme}, @handleDocTheme
    (fetchCorsDomFromUrl "https://www.arconaitv.me/")(
      (dom) -> dom.querySelectorAll linkSelector,
      (map (el) -> {title: (trim el.textContent), url: el.href}),
      (sortBy prop "title"),
      ((showData) ~> @setState {loadingState: 2, showData: showData})
    )

  handleClickOutside: :handleClickOutside (e) ->
    e.preventDefault!
    e.stopPropagation!
    if not e.target.closest(".asl-settings-dialog")
      @toggleSettings!

  toggleSettings: :toggleSettings (e) ->
    isVisible =  not @state.settingsVisible
    document.documentElement[if isVisible then "addEventListener" else "removeEventListener"] "click", @handleClickOutside, false
    @setState {settingsVisible: isVisible}

  handleDocTheme: :handleDocTheme ->
    if @state.colorTheme is "dark"
      document.documentElement.classList.add "dark"
    else
      document.documentElement.classList.remove "dark"

  changeColorTheme: :changeColorTheme (e) ->
    theme = e.target.value
    window.localStorage.setItem "asl-color-theme", theme
    @setState {colorTheme: theme}, @handleDocTheme

  render: :render ->
    if @state.loadingState is 0
      div null, "Loading..."
    else if @state.loadingState is 1
      div null, "Error"
    else
      div null, [
        header {className: "asl-header"}, [
          h1 null, "Arconai Tv Stream Links"
          button {className: "asl-settings-btn", type: "button", onClick: @toggleSettings}, "⚙"
        ]
        if @state.settingsVisible then
          div {className: "asl-settings-dialog"}, [
            label null, [
              span null, "Color theme: "
              select {value: if @state.colorTheme then @state.colorTheme else "light", onChange: @changeColorTheme}, [
                option {value: "light"}, "Light"
                option {value: "dark"}, "Dark"
              ]
            ]
          ]
        ul {className: "asl-list"},
          map ((showData) -> React.createElement ShowListItem, {data: showData}), @state.showData
        footer {className: "asl-footer"}, [
          span null, "All streams are from "
          a {href: "https://www.arconaitv.me/", target: "_blank"}, "Arconai Tv"
          span null, ". I'm sure they'd appreciate your "
          a {href: "https://shop.stwhy.com/", target: "_blank"} "donation"
          span null, "."
        ]
      ]
}


# Side Effects
React.render (React.createElement ShowList), (document.getElementById "app")
