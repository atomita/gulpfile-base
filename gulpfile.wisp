(defmacro gulp-line
  ""
  [& commandline]
  (let [symbol-value
        (fn [symbl]
          (if (symbol? symbl) (get symbl :name) ""))
        
        chunk
        (fn [commandline]
          (loop [backs commandline
                 front nil]
            (if (empty? backs)
              (list front)
              (let [fst (first backs)
                    fst-val (symbol-value fst)
                    ;dd (print "???")
                    ;dd (print f)
                    ;dd (print (symbol? f))
                    ;dd (print (keyword? f))
                    ;dd (print (list? f))
                    ;dd (print (vector? f))
                    ;dd (print (string? f))
                    ;dd (print (dictionary? f))
                    ;dd (print "!!!")
                    fst* (if (dictionary? fst)
                           [fst]
                           fst)
                    ]
                (if (or (= fst-val "|") (= fst-val ">"))
                  (if (symbol? front)
                    (list (list front) backs)
                    (list front backs))
                  (recur (rest backs) (if front (cons front fst*) fst*)))))))

        chunked (chunk commandline)
        
        pipe
        (fn [command form]
          `(.pipe ~form (~@command)))

        dest
        (fn [command form]
          `(.pipe ~form (gulp.dest ~command)))

        firsts
        ((fn [commandline]
           (let [fst (first commandline)
                 fst-val (symbol-value fst)
                 rst (rest commandline)
                 ]
             (if (and fst-val (= "gulp." (fst-val.slice 0 5)))
               commandline
               (if (= (get fst-val 0) ".")
                 `(~fst gulp ~rst)
                 (do
                   (set! (aget (first commandline) :name) (+ "." fst-val))
                   `(~fst gulp ~rst)
                   ))))
           ) (first chunked))
        ]
    (loop [commandline (second chunked)
           form firsts]
      (if commandline
        (let [fname (symbol-value (first commandline))
              chunked (chunk (rest commandline))
              segment (first chunked)
              command (if (= fname "|") (pipe segment form) (dest segment form))
              ]
          (recur (second chunked) command))
        form
        ))))




(ns app.tasks
  "tasks"
  (:require [gulp]
            [gulp-load-plugins]
            [stylus]
            [nib]
            [imagemin-pngcrush :as pngcrush]))

(let [
      plugins (gulp-load-plugins)
      no-convert "!./**/{node_modules|jspm_packages}/**"
      src {:image ["./**/images/**/*.{png,jpg,jpeg,gif,svg}", "!./**/images/**/*.min.*", no-convert]
           :stylus ["./**/*.styl(us)" "!./**/_*.styl(us)" no-convert]
           :coffee ["./**/*.coffee" no-convert]
           :riot ["./**/*.tag" no-convert]
           }
      ]


  (gulp.task :default [:stylus :coffee :riot :watch])

  (gulp.task
   :watch (fn [] (do
                   ;(.watch gulp (.-image src) [:image])
                   (.watch gulp (.-stylus src) [:stylus])
                   (.watch gulp (.-coffee src) [:coffee])
                   (.watch gulp (.-riot src) [:riot])
                   )))

  (gulp.task
   :serve (fn [] (gulp-line
                  src "html"
                  | plugins.webserver {:livereload true, :directoryListing true}
                  )))

  (gulp.task
   :image (fn [] (gulp-line
                  src (.-image src)
                  | plugins.plumber {:errorHandler
                                     (plugins.notify.onError
                                      {:title "task: image"
                                       :message "Error: <%= error.message %>"})
                                     }
                  | plugins.imagemin {:progressive true
                                      :svgoPlugins [{:removeViewBox false}]
                                      :use [(pngcrush)]}
                  | plugins.rename {:suffix ".min"}
                  > "./"
                  )))

  (gulp.task
   :stylus (fn [] (gulp-line
                   src (.-stylus src)
                   | plugins.plumber {:errorHandler
                                      (plugins.notify.onError
                                       {:title "task: stylus"
                                        :message "Error: <%= error.message %>"})
                                      }
                   | plugins.stylus {:define {:url (stylus.resolver)}
                                     "resolve url" true
                                     :use [(nib)]
                                     :import :nib
                                     }
                   > "./"
                   | plugins.minifyCss
                   | plugins.rename {:extname ".min.css"}
                   > "./"
                   )))

  (gulp.task
   :coffee (fn [] (gulp-line
                   src (.-coffee src)
                   | plugins.plumber {:errorHandler
                                      (plugins.notify.onError
                                       {:title "task: coffee"
                                        :message "Error: <%= error.message %>"})
                                      }
                   | plugins.newer {:dest "./" :ext ".min.js"}
                   | plugins.coffeelint
                   | plugins.coffee {:bare true}
                   > "./"
                   | plugins.uglify
                   | plugins.rename {:extname ".min.js"}
                   > "./"
                   )))

  (gulp.task
   :riot (fn [] (gulp-line
            src (.-riot src)
            | plugins.plumber {:errorHandler
                               (plugins.notify.onError
                                {:title "task: riot"
                                 :message "Error: <%= error.message %>"})
                               }
            | plugins.newer {:dest "./" :ext ".js"}
            | plugins.riot {:template :jade}
            | plugins.rename {:extname ".js"}
            > "./"
            )))

  )
