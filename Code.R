---
    title: "Social Media Report"
Author: "José Caloca"
output: 
    flexdashboard::flex_dashboard:
    orientation: columns
social: menu
source_code: embed
runtime: shiny
---
    
    ```{r setup, include=FALSE}
library(plotly)
library(tidyverse)
library(readxl)
library(flexdashboard)
library(shiny)
library(shinyWidgets)
#------------------ Set colours ------------------

# https://www.w3.org/TR/css-color-3/#svg-color
confirmed_color <- "purple"
facebookcol <- "#1f77b4"
instagramcol <- "#be3084"
twittercol <- "#2bc4ff"

#------------------ Load data ------------------

data <- readRDS("data.rds")

# Change to factor the following variables:
data$Network <- as.factor(data$Network) 
data$Message.Type <- as.factor(data$Message.Type)
data$Month <- as.factor(data$Month)
data$Account <- as.factor(data$Account)
data$Agent <- as.factor(data$Agent)
data$Date <- as.Date(data$Date)

# I change the date format to YEAR-month-day

#------------------ Data wrangling ------------------

daily <- data %>% group_by(Date, Network) %>% #data grouped by year and date
    count(Network) %>% # count the number of contact per network
    rename(contacts = n) %>% # rename the column n to "contacts"
    spread(Network, contacts, fill = 0) %>% # splits the Network
    arrange(Date) %>% # sorted date from 01-01 to 31-12
    ungroup() %>% 
    mutate(facebook_cum = cumsum(facebook),
           instagram_cum = cumsum(instagram),
           twitter_cum = cumsum(twitter)) # calculate cummulative frequency

total_contacts_platform <- data %>% group_by(Network) %>% #data grouped by year and date
    count(Network) %>% 
    rename(contacts = n) %>% 
    spread(Network, contacts) %>% 
    mutate(total = facebook + instagram + twitter) #yearly

contacts_agent <- data %>% group_by(Agent, Network) %>% ##distribution
    count() %>%
    rename(contacts = n) %>% 
    spread(Network, contacts) %>% 
    ungroup() %>% 
    mutate(total = (facebook +instagram + twitter)) %>% 
    arrange(-total)

contacts_agent$total <- as.factor(contacts_agent$total)

```

Dashboard
=======================================================================
    
    Row {data-width=228}
-----------------------------------------------------------------------
    
    ### Total 
    
    ```{r}
renderValueBox({
    valueBox(value = paste(format(total_contacts_platform$total, big.mark = ","), "", sep = " "), 
             caption = "Total Contacts", 
             icon = "far fa-flag", 
             color = confirmed_color)
})
```

### Instagram 

```{r}
renderValueBox({
    valueBox(value = paste(format(total_contacts_platform$instagram[1], big.mark = ","), " (",
                           round(100 * total_contacts_platform$instagram[1] / total_contacts_platform$total[1], 1), 
                           "%)", sep = ""), 
             caption = "Instagram contacts", icon = "fab fa-instagram", 
             color = instagramcol)
})
```

### Facebook 

```{r}
renderValueBox({
    valueBox(value = paste(format(total_contacts_platform$facebook[1], big.mark = ","), " (",
                           round(100 * total_contacts_platform$facebook[1] / total_contacts_platform$total[1], 1), 
                           "%)", sep = ""), 
             caption = "Facebook contacts", icon = "fab fa-facebook", 
             color = facebookcol)
})
```

### Twitter {.value-box}

```{r}
renderValueBox({
    valueBox(value = paste(format(total_contacts_platform$twitter[1], big.mark = ","), " (",
                           round(100 * total_contacts_platform$twitter[1] / total_contacts_platform$total[1], 1), 
                           "%)", sep = ""), 
             caption = "Twitter contacts", icon = "fab fa-twitter", 
             color = twittercol)
})
```

Row {.tabset}
-----------------------------------------------------------------------
    
    ### Daily Cumulative Contacts
    
    ```{r}
plotly::plot_ly(data = daily,
                x = ~ Date,
                y = ~ facebook_cum, 
                name = 'Facebook', 
                fillcolor = facebookcol,
                type = 'scatter',
                mode = 'none', 
                stackgroup = 'one') %>%
    plotly::add_trace(y = ~ twitter_cum,
                      name = "Twitter",
                      fillcolor = twittercol) %>% 
    plotly::add_trace(y = ~ instagram_cum,
                      name = "Instagram",
                      fillcolor = instagramcol) %>%
    plotly::layout(title = "",
                   yaxis = list(title = "Cumulative Number of contacts"),
                   xaxis = list(title = "Date",
                                type = "date"),
                   legend = list(x = 0.1, y = 0.9),
                   hovermode = "compare")
```


### Daily contacts

```{r}

daily <- data %>% group_by(Date, Network) %>% #data grouped by year and date
    count(Network) %>% # count the number of contact per network
    rename(contacts = n) %>% # rename the column n to "contacts"
    spread(Network, contacts, fill = 0) %>% # splits the Network
    arrange(Date) %>% # sorted date from 01-01 to 31-12
    ungroup()


daily %>%
    plotly::plot_ly() %>%
    plotly::add_trace(
        x = ~Date,
        y = ~instagram,
        type = "scatter",
        mode = "lines+markers",
        name = "Instagram",
        marker = list(color = instagramcol),
        line = list(color = instagramcol , width = 2)
    ) %>%
    plotly::add_trace(
        x = ~Date,
        y = ~facebook,
        type = "scatter",
        mode = "lines+markers",
        name = "Facebook",
        marker = list(color = facebookcol),
        line = list(color = facebookcol, width = 2)
    ) %>%
    plotly::add_trace(
        x = ~Date,
        y = ~twitter,
        type = "scatter",
        mode = "lines+markers",
        name = "Twitter",
        marker = list(color = twittercol),
        line = list(color = twittercol , width = 2)
    ) %>% 
    plotly::layout(
        title = "",
        legend = list(x = 0.1, y = 0.9),
        yaxis = list(title = "Contacts evolution"),
        xaxis = list(title = "Date"),
        # paper_bgcolor = "black",
        # plot_bgcolor = "black",
        # font = list(color = 'white'),
        hovermode = "compare",
        margin = list(
            # l = 60,
            # r = 40,
            b = 10,
            t = 10,
            pad = 2
        )
    )

```

### Instagram

```{r}
composition <- data %>% 
    group_by(Network, Message.Type) %>% 
    count() %>% # count the number of contact per network
    rename(contacts = n) %>% 
    spread(Network, contacts)

instagram <- plot_ly(composition, 
                     labels = ~Message.Type, 
                     values = ~instagram, type = 'pie') %>% 
    layout(title = 'Composition of Instagram contacts',
           xaxis = list(showgrid = FALSE, 
                        zeroline = FALSE, 
                        showticklabels = FALSE),
           yaxis = list(showgrid = FALSE, 
                        zeroline = FALSE, 
                        showticklabels = FALSE))
instagram
```

### Facebook

```{r}
facebook <- plot_ly(composition, 
                    labels = ~Message.Type, 
                    values = ~facebook, type = 'pie') %>% 
    layout(title = 'Composition of Facebook contacts',
           xaxis = list(showgrid = FALSE, 
                        zeroline = FALSE, 
                        showticklabels = FALSE),
           yaxis = list(showgrid = FALSE, 
                        zeroline = FALSE, 
                        showticklabels = FALSE))

facebook
```

### Twitter

```{r}
twitter <- plot_ly(composition, 
                   labels = ~Message.Type, 
                   values = ~twitter, type = 'pie') %>% 
    layout(title = 'Composition of Twitter contacts',
           xaxis = list(showgrid = FALSE, 
                        zeroline = FALSE, 
                        showticklabels = FALSE),
           yaxis = list(showgrid = FALSE, 
                        zeroline = FALSE, 
                        showticklabels = FALSE))
twitter
```

Contacts per accounts
=======================================================================
    
    Row 
-------------------------------------
    ### Top 30 most frequent accounts in LGN
    
    ```{r}
x <- data %>% group_by(Account, Network)%>% 
    count() %>% 
    arrange(-n) %>%
    rename(contacts = n,
           accounts = Account) %>%  
    filter(contacts >= 7)

p <- plotly::plot_ly(
    data = x[1:30,],
    x = ~accounts,
    y = ~contacts,
    type = "bar",
    marker = list(color = c('rgba(222,45,38,0.8)', rep('rgba(204,204,204,1)', 29)))
) %>% 
    plotly::layout(
        barmode = "stack",
        yaxis = list(title = "Total contacts per account", type = "log"),
        xaxis = list(title = ""),
        hovermode = "compare",
        margin = list(
            # l = 60,
            # r = 40,
            b = 10,
            t = 10,
            pad = 2
        )
    )

p <- layout(p, xaxis = list(categoryarray = ~accounts, categoryorder = "array"))
p
```

row {data-width=200}
-------------------------------------
    
    ### Most frequent users in LGN
    
    ```{r}
tbl <- reactable::reactable(x,
                            pagination = FALSE,
                            highlight = TRUE,
                            height = 370,
                            sortable = TRUE,
                            borderless = TRUE,
                            defaultPageSize = nrow(df_rates),
                            defaultSortOrder = "desc",
                            defaultSorted = "contacts",
                            columns = list(
                                accounts = reactable::colDef(
                                    name = "accounts", 
                                    minWidth = 50, 
                                    maxWidth = 100),
                                contacts = reactable::colDef(
                                    name = "contacts",  
                                    minWidth = 50, 
                                    maxWidth = 100, 
                                    defaultSortOrder = "desc"))
)

library(htmltools)
htmltools::div(class = "standings",
               htmltools::div(class = "title",
                              htmltools::h5("Clich on the columns names to resort the table")
               ),
               tbl,
               paste("Data last updated on", max(data$Date))
)

ui <- fluidPage(
    downloadButton("downloadData", "Download")
)

server <- function(input, output) {
    output$downloadData <- downloadHandler(
        filename = function() {
            paste("data-", "frequent-users", ".csv", sep="")
        },
        content = function(file) {
            write.csv(x, file)
        }
    )
}

shinyApp(ui, server)

```


Contacts per agent
=======================================================================
    
    Row 
-------------------------------------
    ### Contacts per agent
    
    ```{r}
p <- plotly::plot_ly(
    data = contacts_agent,
    x = ~Agent,
    y = ~instagram,
    type = "bar",
    name = "Instagram",
    marker = list(color = instagramcol)
) %>% plotly::add_trace(
    y=~facebook,
    name = "Facebook",
    marker = list(color = facebookcol) 
) %>% plotly::add_trace(
    y = ~twitter,
    name = "Twitter",
    marker = list(color = twittercol)
) %>% 
    plotly::layout(
        barmode = "stack",
        yaxis = list(title = "Total cases", type = "log"),
        xaxis = list(title = ""),
        hovermode = "compare",
        legend = list(x = 0.8, y = 0.9),
        margin = list(
            # l = 60,
            # r = 40,
            b = 10,
            t = 10,
            pad = 2
        )
    )

p <- layout(p, xaxis = list(categoryarray = ~Agent, categoryorder = "array"))
p
```

row {data-width=330}
-------------------------------------
    
    ### Contacts per agent
    
    
    ```{r}
tbl <- reactable::reactable(contacts_agent,
                            pagination = FALSE,
                            highlight = TRUE,
                            height = 370,
                            sortable = TRUE,
                            borderless = TRUE,
                            defaultPageSize = nrow(df_rates),
                            defaultSortOrder = "desc",
                            defaultSorted = "total",
                            columns = list(
                                Agent = reactable::colDef(
                                    name = "assigned to", 
                                    minWidth = 50, 
                                    maxWidth = 100),
                                facebook = reactable::colDef(
                                    name = "facebook",  
                                    minWidth = 50, 
                                    maxWidth = 100, 
                                    defaultSortOrder = "desc"),
                                instagram = reactable::colDef(
                                    name = "instagram",  
                                    minWidth = 50, 
                                    maxWidth = 100),
                                twitter = reactable::colDef(
                                    name = "twitter",  
                                    minWidth = 50, 
                                    maxWidth = 100),
                                total = reactable::colDef(
                                    name = "total",  
                                    minWidth = 50, 
                                    maxWidth = 100))
)

library(htmltools)
htmltools::div(class = "standings",
               htmltools::div(class = "title",
                              htmltools::h5("Clich on the columns names to resort the table")
               ),
               tbl,
               paste("Data last updated on", max(data$Date))
)

ui <- fluidPage(
    downloadButton("downloadData", "Download")
)

server <- function(input, output) {
    output$downloadData <- downloadHandler(
        filename = function() {
            paste("data-", "contact-agents", ".csv", sep="")
        },
        content = function(file) {
            write.csv(contacts_agent, file)
        }
    )
}

shinyApp(ui, server)
```