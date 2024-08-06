#import "@preview/drafting:0.2.0": *

#let margincite(key, mode, prefix, suffix, noteNum, hash) = context {
  if query(bibliography).len()>0 {
    let supplement = suffix.split(",").filter(value => not value.contains("dy.")).join(",")
    let dy = if suffix.contains("dy.") {
      eval(suffix.split("dy.").at(1, default: "").split(",").at(0, default: "").trim())
    } else {-2em}
    if supplement!=none and supplement.len()>0 {cite(key, form: "normal", supplement: supplement)} 
    else {cite(key, form: "normal")}
    
    set text(size: 8pt)

    [#margin-note(dy:dy, dx: .25in)[
        #if supplement!=none and supplement.len()>0  {cite(key, form:"full", supplement: supplement)} else {cite(key, form:"full")}]
    ]
      
    
  }
}

#let wideblock(content, ..kwargs) = block(..kwargs, width:100%+3.5in-.75in, content)


// Fonts used in front matter, sidenotes, bibliography, and captions
#let sans-fonts = (
    "TeX Gyre Heros",
    // "Noto Sans"
  )

// Fonts used for headings and body copy
#let serif-fonts = (
  
  "ETBembo",
  "Heuristica",
  "Merriweather",
  // "Harding Text Web",
  // "Linux Libertine",
)

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#let article(
  title: [Paper Title],
  shorttitle: none,
  subtitle: none,
  authors: none,
  product: none,
  date: none,
  lang: "en",
  region: "US",
  version: none,
  draft: false,
  distribution: none,
  abstract: none,
  abstracttitle: none,
  publisher: none,
  documenttype: none,
  toc: none,
  toc_title: none,
  bib: none,
  first-page-footer: none,
  doc
) = {
  // Document metadata
  // set document(title: title, author: authors.map(author => author.name))

  
  // Page setup
  let lr(l, r, ..kwargs) = wideblock( ..kwargs, 
    grid(columns: (1fr, 4fr), align(left, text(size: 8pt, fill: gray, l)), align(right, text( size: 8pt, fill: gray, r)))
  )
  set page(
    paper: "us-letter",
    margin: (left: .75in, right: 3.5in, top: 1in, bottom: 1in),

 
    header: context {
      
      if counter(page).get().first() > 1 {
        set text(font: serif-fonts, tracking: 1.5pt)
        lr([], 
        [#if shorttitle !=none {upper(shorttitle) } else {upper(title)}
        #text(size: 12pt, [#h(1em)#counter(page).display()])])
      }
    },
    footer: context {
      if counter(page).get().first() < 2 {
        if first-page-footer !=none {first-page-footer}
      } 
    },
    
  )

  set-page-properties()
  set-margin-note-defaults(
    stroke: none,
    side: right,
    page-width: 8.5in-3.5in-.5in-1em,
    margin-right: 3.5in-.75in)
  
  // Just a suttle lightness to decrease the harsh contrast
  set text(fill:luma(30),
          lang: lang,
           region: region,
           historical-ligatures: true,
          )
  
  set par(leading: .75em, justify: true, linebreaks: "optimized", first-line-indent: 1em)
  show par: set block(
    spacing: 0.65em
  )

  // Frontmatter

let authorblock() = [
      #set text(size:12pt, style:"italic")
      #set par(first-line-indent: 0em)
      #for (author) in authors [
          #author.name
          #linebreak() 
          #if author.email != none [#text(size: 7pt, font: "SF Mono", author.email)]
          #linebreak()
  
        ]
      #if date != none {
            let (year, month, day) = date.split("-")
            let day = datetime(year: int(year), month: int(month), day: int(day))
            [#day.display("[month repr:long] [day], [year]")]
            
      }
       
      
  ] 
  
  //title block
  wideblock({
    set par(first-line-indent: 0pt)
    v(-.5cm)
    text(font: sans-fonts, tracking: 1.5pt, fill:gray.lighten(60%), upper(documenttype))
    v(.5cm)
    text(font: serif-fonts,  size:22pt, hyphenate: false, weight:"regular", title)
    linebreak()
    text(font: serif-fonts, size: 16pt,  stretch: 80%, weight: "regular", hyphenate: true, subtitle)
    linebreak()
    if version != none {text(font:sans-fonts, size: 8pt, style: "normal", fill:gray)[#version]} else []
    
    if authors != none {authorblock()}
    
    if abstract != none {
    block(inset: 1.5em)[#text(font: serif-fonts, size: 10pt)[#abstract]]
    } else {v(3em)}
    
  })
  


let tocblock() = {
  
  set par(first-line-indent: 0pt)        
  [#text(size:12pt,weight: "black", [#toc_title])
  #set text(size:.75em, weight: "regular", style: "italic", number-type: "old-style")
  #outline(
    title: none,
    depth: 1,
    indent: 1em, 
  )]
}
    
//TOC
if toc !=none [#margin-note(dx:0em, dy:-1em)[#tocblock()]]





  // Headings
  set heading(numbering: none)
  show heading.where(level:1): it => {
    v(2em,weak:true)
    text(size:14pt, weight: "black",it)
    v(1em,weak: true)
  }

  show heading.where(level:2): it => {
    v(1.3em, weak: true)
    text(size: 13pt, weight: "regular",style: "italic",it)
    v(1em,weak: true)
  }

  show heading.where(level:3): it => {
    v(1em,weak:true)
    text(size:11pt,style:"italic",weight:"thin",it)
    v(0.65em,weak:true)
  }

  show heading: it => {
    if it.level <= 3 {it} else {}
  }


  // Tables and figures
  show figure: set figure.caption(separator: [.#h(0.5em)])
  show figure.caption: set align(left)
  show figure.caption: set text(font: sans-fonts)

  show figure.where(kind: table): set figure.caption(position: top)
  show figure.where(kind: table): set figure(numbering: "I")
  
  show figure.where(kind: image): set figure(supplement: [Figure], numbering: "1")
  
  show figure.where(kind: raw): set figure.caption(position: top)
  show figure.where(kind: raw): set figure(supplement: [Code], numbering: "1")
  show raw: set text(font: "SF Mono", size: 8pt, ligatures: false)
  

  // Equations
  set math.equation(numbering: "(1)")
  show math.equation: set block(spacing: 0.65em)

  show link: underline

  // Lists
  set enum(
    indent: 1em,
    body-indent: 1em,
  )
  show enum: set par(justify: false)
  set list(
    indent: 1em,
    body-indent: 1em,
  )
  show list: set par(justify: false)


  // Body text
  set text(
    font: serif-fonts,
    style: "normal",
    weight: "regular",
    hyphenate: true,
    size: 10pt
  )

  
  show cite.where(form:"prose"): none

  set text(size: 12pt)
  v(-.5in)
  doc

  show bibliography: set text(font:sans-fonts)
  show bibliography: set par(justify:false)
  set bibliography(title:none)
  if bib != none {
    heading(level:1,[References])
    bib
  }


}

  




  