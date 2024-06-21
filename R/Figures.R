# @file Figures
#
# Copyright 2023 Darwin EU Coordination Center
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

.recordsCountPlot <- function(df, log_y_axis = FALSE, hide_legend = FALSE) {
  plot <- df %>%
    dplyr::mutate(
      Date = lubridate::parse_date_time(.data$X_CALENDAR_MONTH, "ym"),
      Domain = .data$SERIES_NAME,
      Count = .data$Y_RECORD_COUNT
    ) %>%
    ggplot2::ggplot(
      aes(x = .data$Date, y = .data$Count)
    ) +
    ggplot2::geom_line(
      aes(color = .data$Domain)
    ) +
    ggplot2::scale_colour_hue(
      l = 40
    )

  if (log_y_axis) {
    plot <- plot + ggplot2::scale_y_log10()
  }

  if (hide_legend) {
    plot <- plot + ggplot2::theme(legend.position = "none")
  }

  return(plot)
}

.heatMapPlot <- function(df, yVar) {
  # https://rpubs.com/melike/heatmapTable
  maxYVar <- length(unique(df[[yVar]]))
  df %>%
    dplyr::group_by(.data$DOMAIN) %>%
    dplyr::mutate(
      PROPORTION = .data$N_RECORDS / sum(.data$N_RECORDS) * 100
    ) %>%
    dplyr::ungroup() %>%
    ggplot2::ggplot(
      aes(x = .data$DOMAIN, y = .data[[yVar]])
    ) +
    ggplot2::geom_tile(
      aes(fill = .data$PROPORTION)
    ) +
    ggplot2::geom_text(
      aes(label = .data$N_RECORDS)
    ) +
    ggplot2::scale_fill_gradient2(
      low = scales::muted("midnightblue"),
      mid = "white",
      high = scales::muted("darkred"),
      n.breaks = 4,
      midpoint = 1 / maxYVar * 100 # expected average proportion
    ) +
    ggplot2::theme(
      # no gridlines
      panel.grid.major.x = element_blank(),
      panel.grid.minor.x = element_blank(),
      panel.grid.major.y = element_blank(),
      panel.grid.minor.y = element_blank(),
      panel.background = element_rect(fill = "white"),
      axis.text.x = element_text(size = 6, face = "bold"),
      axis.text.y = element_text(size = 12, face = "bold"),
      legend.position = "bottom"
    ) +
    ggplot2::scale_x_discrete(
      name = ""
    ) +
    ggplot2::scale_y_reverse(
      name = "",
      breaks = seq(1, maxYVar)
    ) +
    ggplot2::labs(
      fill = "Proportion (%)"
    )
}
