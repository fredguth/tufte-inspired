// Some definitions presupposed by pandoc's typst output.


#let blockquote(body) = [
  #set text( size: 0.8em )
  #align(right, block(inset: (right: 5em, top: 0.2em, bottom: 0.2em))[#body])
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): block.with(
    fill: luma(245), 
    width: 100%, 
    inset: 8pt, 
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}
// #show figure: it => {
//   let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
//   if kind_match == none {
//     return it
//   }
// }
// #show figure.where(kind: kind.matches(regex(""))): none 
// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  set par(first-line-indent: 0em)
 
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    new_title_block +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: luma(245), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: white, width: 100%, inset: 8pt, body))
      }
    )
}
#show figure: set text(size: 8pt)
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

  




  
#show: doc => article(
  title: [A Tufte Inspired Manuscript],
    subtitle: [Using Quarto… and Typst!],
  
  authors: (
                    ( name: [Tufte Inspired Developers],
            affiliation: [],
            location: [],
            role: [],
            email: [github.com/fredguth/tufte-inspired] ),
              
  ),
         
  date: "2024-08-05",

  abstract: [This #strong[Tufte Inspired] manuscript format for Quarto honors Edward Tufte’s distinctive style. It simplifies creating handout-like documents and websites by emulating the aesthetics of Tufte’s books. This document serves two purposes: It showcases the format and acts as an evolving authoring guide.

],
  abstracttitle: "Abstract",
  toc: true,
  version: [v.1.0],
publisher: "Publisher",
documenttype: [Handout],
  toc_title: [Table of contents],
// //   toc_depth: 3,
  // cols: 1,
  doc,
)


= Introduction
<introduction>
#margin-note(dx:0em, dy:-11cm)[#set text(size: 8pt);#set par(first-line-indent: 0em)
#figure([
#box(width: 75%,image("./Images/et_midjourney_transparent.png"))
], caption: figure.caption(
position: bottom, 
[
Edward R. Tufte, godfather of charts, slayer of slide decks. Art by Fred Guth and MidJourney.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


]; #set text(size: 12pt); 
Professor Emeritus of Political Science, Statistics and Computer Sciente at Yale University, Edward Tufte is an expert in the presentation of informational.

Tufte’s style is known for extensive use of sidenotes, integration of graphics with text and typography#footnote[Tufte’s #link("https://www.edwardtufte.com/tufte/")[website];: #link("https://www.edwardtufte.com/tufte/");];.

#set text(size: 8pt); #block(width: 100%+3.5in-0.75in)[
#figure([
#box(image("./Images/Minard.png"))
], caption: figure.caption(
position: bottom, 
[
Minard’s map of Napoleon’s Russian campaign, described by Edward Tufte as "may well be the best statistical graphic ever drawn" #margincite(<Tufte:vdqi>, "AuthorInText", "", "dy.-11cm", none, 0).
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


]; #set text(size: 12pt); 
= Usage
<usage>
== Arbitrary Margin Content
<arbitrary-margin-content>
You can include anything in the margin by places the class `.column-margin` on the element. See an example on the right about the first fundamental theorem of calculus.

#margin-note(dx:0em, dy:-6em)[#set text(size: 8pt);#set par(first-line-indent: 0em)
We know from #emph[the first fundamental theorem of calculus] that for $x$ in $[a , b]$:

$ frac(d, d x) (integral_a^x f (u) thin d u) = f (x) . $ #set text(size: 12pt); ]

== Arbitrary Full Width Content
<arbitrary-full-width-content>
Any content can span to the full width of the page, simply place the element in a `div` and add the class `column-page-right`. For example, the following code will display its contents as full width.

```md
::: {.fullwidth}
Any _full width_ content here.
:::
```

Below is an example:

#set text(size: 8pt); #block(width: 100%+3.5in-0.75in)[
#figure([
#box(image("index_files/figure-typst/fullwidth-1.svg"))
], caption: figure.caption(
position: bottom, 
[
A full width figure.
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


]; #set text(size: 12pt); 
#block[
#heading(
level: 
1
, 
outlined: 
false
, 
[
Acknowledgements
]
)
]
Thanks to the Quarto and Typst teams for these wonderful tools. This format is made possible by #link("https://github.com/quarto-dev/quarto-cli/discussions?discussions_q=author%3Afredguth")[Quarto’s community];. Special thanks to:

- Mickaël Canouil (`@mcanouil`);
- Gordon Woodhull (`@gordonwoodhull`);
- Charles Teague (`@dragonstyle`);
- Raniere Silva (`@rgaiacs`); and
- Christophe Dervieux (`@cderv`)

#set bibliography(style: "springer-humanities-author-date")

#bibliography("references.bib")

