# @file OfficerHelper
#
# Copyright 2024 Darwin EU Coordination Center
#
# This file is part of CdmOnboarding
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# @author Darwin EU Coordination Center
# @author Peter Rijnbeek
# @author Maxim Moinat

prettyHr <- function(x) {
  result <- sprintf("%.2f", x)
  result[is.na(x)] <- "NA"
  result <- suppressWarnings(format(as.numeric(result), big.mark = ",")) # add thousands separator
  return(result)
}

prettyPc <- function(x) {
  result <- sprintf("%.1f%%", x)
  result[is.na(x)] <- "NA"
  result[x == 100] <- "100%"
  result[x == 0] <- "0%"
  return(result)
}

my_caption <- function(x, caption, sourceSymbol, style) {
  officer::body_add_par(
    x,
    value = sprintf(
      "%s %s",
      caption,
      dplyr::coalesce(sourceSymbol, '')
    ),
    style = style
  )
}

my_table_caption <- function(x, caption, sourceSymbol) {
  my_caption(x, caption, sourceSymbol, style = pkg.env$styles$tableCaption)
}

my_figure_caption <- function(x, caption, sourceSymbol) {
  my_caption(x, caption, sourceSymbol, style = pkg.env$styles$figureCaption)
}

my_body_add_table <- function(x, value, pos = "after", header = TRUE,
          alignment = NULL, first_row = TRUE, first_column = FALSE, last_row = FALSE, last_column = FALSE,
          no_hband = FALSE, no_vband = TRUE, align = "left", auto_format = TRUE) {
  if (is.null(value)) {
    return(x)
  }
  pt <- officer::prop_table(
    style = pkg.env$styles$table,
    layout = officer::table_layout(),
    width = officer::table_width(),
    stylenames = officer::table_stylenames(),
    tcf = officer::table_conditional_formatting(
      first_row = first_row,
      first_column = first_column,
      last_row = last_row,
      last_column = last_column,
      no_hband = no_hband,
      no_vband = no_vband
    ),
    align = align
  )

  if (auto_format) {
    # Align left if no alignment is given
    if (is.null(alignment)) {
      alignment <- rep('l', ncol(value))
    }

    # Formatting numeric columns: align right and add thousands separator.
    for (i in seq_len(ncol(value))) {
      if (is.numeric(value[, i])) {
        value[, i] <- format(value[, i], big.mark = ",")
        alignment[i] <- 'r'
      }
    }
  }

  bt <- officer::block_table(
    x = value,
    header = header,
    properties = pt,
    alignment = alignment
  )
  xml_elt <- officer::to_wml(bt, add_ns = TRUE, base_document = x)
  officer::body_add_xml(x, str = xml_elt, pos = pos)
}

my_body_add_runtime <- function(x, duration) {
  if (is.null(duration) || duration <= 0) {
    officer::body_add_par(x, "No query duration found", style = pkg.env$styles$footnote)
    return(x)
  }

  officer::body_add_par(x, sprintf("Query executed in %.2f seconds", duration), style = pkg.env$styles$footnote)
}

my_body_add_table_runtime <- function(x, data, duration = NULL, ...) {
  if (is.null(duration)) {
    duration <- data$duration
  }

  x %>% 
    my_body_add_table(data$result, ...) %>%
    my_body_add_runtime(duration)
}

my_table <- function(x, data, caption, sourceSymbol, duration = NULL, ...) {
  if (is.null(data$result)) {
    caption <- sprintf("Omitted because the query did not return results.")
  }

  if (is.null(duration)) {
    duration <- data$duration
  }

  x %>% 
    my_table_caption(caption, sourceSymbol) %>%
    my_body_add_table_runtime(data, duration, ...)
}

my_source_value_count_section <- function(x, data, domain, kind, smallCellCount) {
  n <- nrow(data$result)

  msg <- "Counts are rounded up to the nearest hundred."
  if (!is.null(smallCellCount)) {
    msg <- sprintf("%s Values with a record count <=%d are omitted.", msg, smallCellCount)
  }

  caption <- sprintf("Top 25 %s %s. %s", kind, domain, msg)
  if (is.null(n)) {
    caption <- sprintf("Omitted because the %s %s query did not return results.", kind, domain)
  } else if (n == 0) {
    caption <- sprintf("Omitted because no %s %s were found with a count >%d.", kind, domain, smallCellCount)
  } else if (n < 25) {
    caption <- sprintf("All %d %s %s. %s", n, kind, domain, msg)
  }
  x <- my_table_caption(x, caption, sourceSymbol = pkg.env$sources$cdm)

  if (!is.null(n) && n > 0) {
    data$result$`%Records` <- prettyPc(data$result$`%Records`)
    if (kind == 'unmapped') {
      alignment <- c('r', 'l', 'r', 'r') # #,name,n,%
    } else {
      alignment <- c('r', 'l', 'l', 'r', 'r') # #,concept_id,name,n,%
    }
    x <- my_body_add_table(
      x,
      value = data$result,
      alignment = alignment
    )
  }

  my_body_add_runtime(x, data$duration)
}

my_unmapped_section <- function(x, data, domain, smallCellCount) {
  if (!is.null(data$result)) {
    names(data$result) <- c("#", "Source Value", "#Records", "%Records")
  }
  my_source_value_count_section(x, data, domain, "unmapped", smallCellCount)
}

my_mapped_section <- function(x, data, domain, smallCellCount) {
  if (!is.null(data$result)) {
    names(data$result) <- c("#", "Concept id", "Concept Name", "#Records", "%Records")
  }
  my_source_value_count_section(x, data, domain, "mapped", smallCellCount)
}
