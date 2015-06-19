
(defmacro ->
  "method chaining."
  [& operations]
  (reduce
   (fn [form operation]
     (cons (first operation)
           (cons form (rest operation))))
   (first operations)
   (rest operations)))

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
           (->
            (.src gulp :html)
            (.pipe (.webserver plugins {:livereload true, :directoryListing true}))
            )))

  (.task gulp :image
         (fn []
           (->
            (.src gulp (.-image src))
            (.pipe (.plumber plugins
                             {:errorHandler (.onError notify
                                                      {:title "task: image"
                                                       :message "Error: <%= error.message %>"})}))
            (.pipe (.imagemin plugins
                              {:progressive true
                               :svgoPlugins [{:removeViewBox false}]
                               :use [(pngcrush)]}))
            (.pipe (.rename plugins {:suffix ".min"}))
            (.pipe (.dest gulp "./"))
            )))

  (.task gulp :stylus
         (fn []
           (->
            (.src gulp (.-stylus src))
            (.pipe (.plumber plugins
                             {:errorHandler (.onError notify
                                                      {:title "task: stylus"
                                                       :message "Error: <%= error.message %>"})}))
            (.pipe (.stylus plugins {:define {:url (.resolver stylus)}
                                     "resolve url" true
                                     :use [(nib)]
                                     :import :nib
                                     }))
            (.pipe (.dest gulp "./"))
            (.pipe (.minifyCss plugins))
            (.pipe (.rename plugins {:extname ".min.css"}))
            (.pipe (.dest gulp "./"))
            )))

  (.task gulp :coffee
         (fn []
           (->
            (.src gulp (.-coffee src))
            (.pipe (.plumber plugins
                             {:errorHandler (.onError notify
                                                      {:title "task: coffee"
                                                       :message "Error: <%= error.message %>"})}))
            (.pipe (.newer plugins {:dest "./" :ext ".min.js"}))
            (.pipe (.coffeelint plugins))
            (.pipe (.coffee plugins {:bare true}))
            (.pipe (.dest gulp "./"))
            (.pipe (.uglify plugins))
            (.pipe (.rename plugins {:extname ".min.js"}))
            (.pipe (.dest gulp "./"))
            )))

  (.task gulp :riot
         (fn []
           (->
            (.src gulp (.-riot src))
            (.pipe (.plumber plugins
                             {:errorHandler (.onError notify
                                                      {:title "task: riot"
                                                       :message "Error: <%= error.message %>"})}))
            (.pipe (.newer plugins {:dest "./" :ext ".js"}))
            (.pipe (.riot plugins {:template :jade}))
            (.pipe (.rename plugins {:extname ".js"}))
            (.pipe (.dest gulp "./"))
            )))

)
