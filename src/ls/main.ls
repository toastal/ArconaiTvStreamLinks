{__, apply, converge, gte, invoker, lt, map, partialRight, path, pipe, pipeP, prop, sortBy, tap, trim, T} = R

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


# httpStatusError : Int -> Bool
httpStatusError =
  converge R.and, [(lt __, 200), (gte __, 400)]


# only does happy path at the moment
# fetchDomCorsFromUrl : String -> (Response -> ()) -> (HTMLDocument -> ())
fetchCorsDomFromUrl = :fetchDomFromUrl (url, errorFn) ~>
  corsUrl = "https://crossorigin.me/" + url
  if navigator.onLine
    (...pipeline) ~>
      apply(pipeP, [
        (partialRight fetch, [{mode: "cors"}])
        (R.when (pipe (prop "status"), httpStatusError), (resp) ~> if typeof errorFn is "function" then errorFn resp)
        (invoker 0, "text")
        domFromHtmlStr
      ].concat(pipeline))(corsUrl)
  else if typeof errorFn is "function"
    errorFn "Device Offline"


# ShowListItem : ReactClass
ShowListItem = React.createClass {
  display: "ShowListItem"

  propTypes: {
    data : PT.objectOf(PT.string)
  }

  getInitialState: :getIntialState ->
    {
      isLoading : false
      href      : ""
    }

  fetchStream: :fetchStream (e) ->
    e.preventDefault!
    e.target.blur!
    @setState {isLoading: true}
    fetchCorsDomFromUrl(@props.data.url, (err) ~> alert err)(
      ((dom) -> dom.querySelector(".flowplayer video>source[type='application/x-mpegurl']")),
      (prop "src"),
      ((src) ~>
        @setState {isLoading: false}
        if src
          @setState {href: src}
          # The Cordova app uses a native call to a plugin I made
          if path ["cordova", "platformId"], window is "android" and window.viewFileFromUrl
            window.viewFileFromUrl T, ((err) -> alert "File Handle Error: " + err), src
          else
            window.open src, "_self")
    )

  render: :render ->
    li {className: "asl-list-item"}, [
      a {className: "asl-list-link", href: @state.href, target: "_blank", onClick: @fetchStream}, [
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
      showData        : []
    }

  componentDidMount: :componentDidMount ->
    storedTheme = window.localStorage.getItem "asl-color-theme"
    if storedTheme then @setState {colorTheme: storedTheme}, @handleDocTheme
    @fetchStreamLinks!

  fetchStreamLinksError: :fetchStreamLinksError (resp) ~>
    if not navigator.onLine and window.localStorage.getItem "streamLinks"
      @setState {loadingState: 3, showData: JSON.parse window.localStorage.streamLinks}
    else
      @setState {loadingstate: 1, errorMsg: "Response status #{resp.status}"}

  fetchStreamLinks: :fetchStreamLinks (e) ->
    if not navigator.onLine and window.localStorage.getItem "streamLinks"
      @setState {loadingState: 3, showData: JSON.parse window.localStorage.streamLinks}
    else
      @setState {loadingState: 0, showData: []}
      (fetchCorsDomFromUrl "https://www.arconaitv.me/", @fetchStreamLinksError.bind(this))(
        (apply (invoker 1, "querySelectorAll"), [linkSelector]),
        (map (el) -> {title: (trim el.textContent), url: el.href}),
        (sortBy prop "title"),
        ((showData) ~>
          window.localStorage.setItem "streamLinks", (JSON.stringify showData)
          @setState {loadingState: 2, showData: showData}
        )
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
      div null, "Error" + if @state.errorMsg then ": #{@state.errorMsg}" else ""
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
            button {type: "button", onClick: ((e) ~>
                                                console.log "test", e)}, "Refresh Stream List"
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
