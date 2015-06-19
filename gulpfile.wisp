(let [
      gulp (require :gulp)
      plugins ((require :gulp-load-plugins))
      notify (.-notify plugins)
      pngcrush (require :imagemin-pngcrush)
      stylus (require :stylus)
      nib (require :nib)
      no-convert "!./**/{node_modules|jspm_packages}/**"
      src {:image ["./**/images/**/*.{png,jpg,jpeg,gif,svg}", "!./**/images/**/*.min.*", no-convert]
           :stylus ["./**/*.styl(us)" "!./**/_*.styl(us)" no-convert]
           :coffee ["./**/*.coffee" no-convert]
           :riot ["./**/*.tag" no-convert]
           }
      ]


  (.task gulp :default [:stylus :coffee :riot :watch])

  (.task gulp :watch
         (fn []
           (do
             ;(.watch gulp (.-image src) [:image])
             (.watch gulp (.-stylus src) [:stylus])
             (.watch gulp (.-coffee src) [:coffee])
             (.watch gulp (.-riot src) [:riot])
             )
           ))

  (.task gulp :serve
         (fn []
           (.pipe
            (.src gulp :html)
            (.webserver plugins {:livereload true, :directoryListing true}))
           ))

  (.task gulp :image
         (fn []
           (.pipe
            (.pipe
             (.pipe
              (.pipe
               (.src gulp (.-image src))
               (.plumber plugins
                         {:errorHandler (.onError notify
                                                  {:title "task: image"
                                                   :message "Error: <%= error.message %>"})}))
              (.imagemin plugins
                         {:progressive true
                          :svgoPlugins [{:removeViewBox false}]
                          :use [(pngcrush)]}))
             (.rename plugins {:suffix ".min"}))
            (.dest gulp "./"))
           ))

  (.task gulp :stylus
         (fn []
           (.pipe
            (.pipe
             (.pipe
              (.pipe
               (.pipe
                (.pipe
                 (.src gulp (.-stylus src))
                 (.plumber plugins
                           {:errorHandler (.onError notify
                                                    {:title "task: stylus"
                                                     :message "Error: <%= error.message %>"})}))
                (.stylus plugins {:define {:url (.resolver stylus)}
                                  "resolve url" true
                                  :use [(nib)]
                                  :import :nib
                                  }))
               (.dest gulp "./"))
              (.minifyCss plugins))
             (.rename plugins {:extname ".min.css"}))
            (.dest gulp "./"))
           ))

  (.task gulp :coffee
         (fn []
           (.pipe
            (.pipe
             (.pipe
              (.pipe
               (.pipe
                (.pipe
                 (.pipe
                  (.pipe
                   (.src gulp (.-coffee src))
                   (.plumber plugins
                             {:errorHandler (.onError notify
                                                      {:title "task: coffee"
                                                       :message "Error: <%= error.message %>"})}))
                  (.newer plugins {:dest "./" :ext ".min.js"}))
                 (.coffeelint plugins))
                (.coffee plugins {:bare true}))
               (.dest gulp "./"))
              (.uglify plugins))
             (.rename plugins {:extname ".min.js"}))
            (.dest gulp "./"))
           ))

  (.task gulp :riot
         (fn []
           (.pipe
            (.pipe
             (.pipe
              (.pipe
               (.pipe
                (.src gulp (.-riot src))
                (.plumber plugins
                          {:errorHandler (.onError notify
                                                   {:title "task: riot"
                                                    :message "Error: <%= error.message %>"})}))
               (.newer plugins {:dest "./" :ext ".js"}))
              (.riot plugins {:template :jade}))
             (.rename plugins {:extname ".js"}))
            (.dest gulp "./"))
           ))

)
