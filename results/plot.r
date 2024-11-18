library(ggplot2)
library(dplyr)
library(patchwork)
library(stringr)
library(tikzDevice)

use_tikz = TRUE

if (use_tikz) {
  lpos = c(0.18, 0.85)
  lpos_offline = c(0.47, 0.9)
} else {
  lpos = c(0.1, 0.9)
  lpos_offline = c(0.275, 0.9)
}

times_main = "results_stats-prepared-main.csv"
times_app  = "results_stats-prepared-appendix.csv"
offline    = "results_stats-offline-prepared-all.csv"

data_times_main = read.csv(file = times_main, sep=",", dec=".")
data_times_app  = read.csv(file = times_app, sep=",", dec=".")
data_offline    = read.csv(file = offline, sep=",", dec=".")

data_times_main["algo"][data_times_main["algo"] == "aACP"] = "$\\alpha$-ACP"
data_times_main = rename(data_times_main, "Algorithm" = "algo")
data_times_app["algo"][data_times_app["algo"] == "aACP"] = "$\\alpha$-ACP"
data_times_app = rename(data_times_app, "Algorithm" = "algo")


if (use_tikz) {
  tikz("plot-times-avg.tex", standAlone = FALSE, width = 2.6, height = 1.4)
} else {
  pdf(file = "plot-times-avg.pdf", height = 2.4)
}

p1 <- ggplot(data_times_main, aes(x=d, y=mean_t, group=Algorithm, color=Algorithm)) +
  geom_line(aes(group=Algorithm, linetype=Algorithm, color=Algorithm)) +
  geom_point(aes(group=Algorithm, shape=Algorithm, color=Algorithm)) +
  xlab("$d$") +
  ylab("time (ms)") +
  scale_y_log10() +
  theme_classic() +
  theme(
    axis.line.x = element_line(arrow = grid::arrow(length = unit(0.1, "cm"))),
    axis.line.y = element_line(arrow = grid::arrow(length = unit(0.1, "cm"))),
    axis.title = element_text(size=10),
    legend.position = lpos,
    legend.title = element_blank(),
    legend.text = element_text(size=8),
    legend.background = element_rect(fill = NA),
    legend.spacing.y = unit(0, 'mm')
  ) +
  guides(fill = "none") +
  scale_shape_manual(values=c(19, 15)) +
  scale_color_manual(values=c(
    rgb(230,159,0, maxColorValue=255),
    rgb(46,37,133, maxColorValue=255)
  )) +
  scale_fill_manual(values=c(
    rgb(230,159,0, maxColorValue=255),
    rgb(46,37,133, maxColorValue=255)
  ))

p1
dev.off()

if (use_tikz) {
  tikz("plot-offline-all.tex", standAlone = FALSE, width = 2.8, height = 1.4)
} else {
  pdf(file = "plot-offline-all.pdf", height = 2.4)
}

data_offline_main = filter(data_offline, d >= 8)
p2 <- ggplot(data_offline_main, aes(x=as.factor(d), y=beta, color=as.factor(p))) +
  geom_boxplot(alpha=0.2) +
  xlab("$d$") +
  ylab("$\\beta$") +
  theme_classic() +
  theme(
    axis.line.x = element_line(arrow = grid::arrow(length = unit(0.1, "cm"))),
    axis.line.y = element_line(arrow = grid::arrow(length = unit(0.1, "cm"))),
    axis.title = element_text(size=10),
    legend.position = lpos_offline,
    legend.direction = "horizontal",
    legend.title = element_blank(),
    legend.text = element_text(size=8),
    legend.background = element_rect(fill = NA),
    legend.spacing.y = unit(0, 'mm')
  ) +
  scale_y_log10(labels = function(x) format(round(x, 1), scientific = FALSE)) +
  guides(fill = "none") +
  scale_color_manual(
    values = c(
      rgb(230,159,0, maxColorValue=255),
      rgb(0,77,64, maxColorValue=255),
      rgb(170,68,153, maxColorValue=255),
      rgb(46,37,133, maxColorValue=255)
    ),
    breaks = c("0.01", "0.05", "0.1", "0.15"),
    labels = c("$0.01$", "$0.05$", "$0.1$", "$0.15$")
    #labels = c("$p=0.01$", "$p=0.05$", "$p=0.1$", "$p=0.15$")
  )

p2
dev.off()

for (pval in c(0.01, 0.05, 0.1, 0.15)) {
    data_times_app_filtered = filter(data_times_app, p == pval)
    data_offline_app_filtered = filter(data_offline, p == pval)

    if (use_tikz) {
      tikz(paste("plot-times-p=", pval, ".tex", sep=""), standAlone = FALSE, width = 2.6, height = 1.4)
    } else {
      pdf(file = paste("plot-times-p=", pval, ".pdf", sep=""), height = 2.4)
    }

    p1 <- ggplot(data_times_app_filtered, aes(x=d, y=mean_t, group=Algorithm, color=Algorithm)) +
      geom_line(aes(group=Algorithm, linetype=Algorithm, color=Algorithm)) +
      geom_point(aes(group=Algorithm, shape=Algorithm, color=Algorithm)) +
      xlab("$d$") +
      ylab("time (ms)") +
      scale_y_log10() +
      theme_classic() +
      theme(
        axis.line.x = element_line(arrow = grid::arrow(length = unit(0.1, "cm"))),
        axis.line.y = element_line(arrow = grid::arrow(length = unit(0.1, "cm"))),
        axis.title = element_text(size=10),
        legend.position = lpos,
        legend.title = element_blank(),
        legend.text = element_text(size=8),
        legend.background = element_rect(fill = NA),
        legend.spacing.y = unit(0, 'mm')
      ) +
      guides(fill = "none") +
      scale_shape_manual(values=c(19, 15)) +
      scale_color_manual(values=c(
        rgb(230,159,0, maxColorValue=255),
        rgb(46,37,133, maxColorValue=255)
      )) +
      scale_fill_manual(values=c(
        rgb(230,159,0, maxColorValue=255),
        rgb(46,37,133, maxColorValue=255)
      ))

    print(p1)
    dev.off()

    if (use_tikz) {
      tikz(paste("plot-offline-p=", pval, ".tex", sep=""), standAlone = FALSE, width = 2.8, height = 1.4)
    } else {
      pdf(file = paste("plot-offline-p=", pval, ".pdf", sep=""), height = 2.4)
    }

    p2 <- ggplot(data_offline_app_filtered, aes(x=as.factor(d), y=beta, group=as.factor(d))) +
      geom_boxplot(color=rgb(46,37,133, maxColorValue=255), fill=rgb(46,37,133, maxColorValue=255), alpha=0.2) +
      xlab("$d$") +
      ylab("$\\beta$") +
      theme_classic() +
      theme(
        axis.line.x = element_line(arrow = grid::arrow(length = unit(0.1, "cm"))),
        axis.line.y = element_line(arrow = grid::arrow(length = unit(0.1, "cm"))),
        axis.title = element_text(size=10),
        legend.position = lpos_offline,
        legend.direction = "horizontal",
        legend.title = element_blank(),
        legend.text = element_text(size=8),
        legend.background = element_rect(fill = NA),
        legend.spacing.y = unit(0, 'mm')
      ) +
      scale_y_log10(labels = function(x) format(round(x, 1), scientific = FALSE)) +
      guides(fill = "none")

    print(p2)
    dev.off()
}