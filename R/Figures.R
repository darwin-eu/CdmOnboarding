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

.recordsCountPlot <- function(results, log_y_axis = FALSE) {
  temp <- results %>%
    dplyr::rename(Date = X_CALENDAR_MONTH, Domain = SERIES_NAME, Count = Y_RECORD_COUNT) %>%
    dplyr::mutate(Date = lubridate::parse_date_time(Date, "ym"))
  plot <- ggplot2::ggplot(temp, aes(x = Date, y = Count)) +
    ggplot2::geom_line(aes(color = Domain)) +
    ggplot2::scale_colour_hue(l = 40)

  if (log_y_axis) {
    plot <- plot + ggplot2::scale_y_log10()
  }

  return(plot)
}

.heatMapPlot <- function(df, yVar) {
  maxYVar <- max(df[[yVar]])
  df %>%
    dplyr::group_by(DOMAIN) %>%
    dplyr::mutate(
        PROPORTION = N_RECORDS / sum(N_RECORDS) * 100
    ) %>%
    dplyr::ungroup() %>%
    ggplot2::ggplot(aes(x = DOMAIN, y = .data[[yVar]])) +
    ggplot2::geom_tile(aes(fill = PROPORTION)) +
    ggplot2::geom_text(aes(label = N_RECORDS)) +
    ggplot2::scale_fill_gradient2(
        low = scales::muted("midnightblue"),
        mid = "white",
        high = scales::muted("darkred"),
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
        axis.text.y = element_text(size = 12, face = "bold")
    ) +
    ggplot2::scale_x_discrete(name = "Domain") +
    ggplot2::scale_y_reverse(
        name = yVar,
        breaks = seq(1, maxYVar)
    ) +
    ggplot2::labs(fill = "Proportion (%)")
}
