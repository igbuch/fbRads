#' Create a new FB custom audience
#' @references \url{https://developers.facebook.com/docs/marketing-api/custom-audience-targeting/v2.3#create}
#' @param fbacc FB_Ad_account object returned by \code{fbad_init}
#' @param name string
#' @param description optional string
#' @param opt_out_link optional link
#' @return custom audience ID
#' @export
fbad_create_audience <- function(fbacc, name, description, opt_out_link) {

    fbad_check_fbacc(fbacc)
    if (missing(name))
        stop('The custom audience name is required.')

    flog.info(paste('Creating new custom audience:', name))

    ## params
    params <- list(access_token = fbacc$access_token, name = name)
    if (!missing(description)) {
        params$description <- description
    }
    if (!missing(opt_out_link)) {
        params$opt_out_link <- opt_out_link
    }

    ## get results
    res <- fbad_request(
        path   = paste0('act_', fbacc$account_id, '/customaudiences'),
        method = "POST",
        params = params)

    ## return ID
    fromJSON(res)$id

}


#' Read metadata on a FB custom audience
#' @references \url{https://developers.facebook.com/docs/marketing-api/custom-audience-targeting/v2.3#read}
#' @param fbacc FB_Ad_account object returned by \code{fbad_init}
#' @param audience_id numeric
#' @param fields character vector of fields to be returned
#' @return custom audience ID
#' @export
fbad_read_audience <- function(fbacc, audience_id, fields = c('id', 'account_id', 'approximate_count','data_source', 'delivery_status', 'lookalike_audience_ids', 'lookalike_spec', 'name', 'permission_for_actions', 'operation_status', 'subtype', 'time_updated')) {

    ## get fields
    fields <- match.arg(fields, several.ok = TRUE)
    fields <- paste(fields, collapse = ',')

    fbad_check_fbacc(fbacc)
    if (missing(audience_id))
        stop('A custom audience id is required.')

    ## get results
    res <- fbad_request(
        path   = paste0(audience_id, '?fields=', fields),
        method = "GET",
        params = list(access_token = fbacc$access_token))

    ## return
    fromJSON(res)

}


#' Delete a FB custom audience
#' @references \url{https://developers.facebook.com/docs/marketing-api/custom-audience-targeting/v2.3#delete}
#' @param fbacc FB_Ad_account object returned by \code{fbad_init}
#' @param audience_id numeric
#' @return custom audience ID
#' @export
fbad_delete_audience <- function(fbacc, audience_id) {

    fbad_check_fbacc(fbacc)
    if (missing(audience_id))
        stop('A custom audience id is required.')

    stop('This is untested code.')

    ## get results
    res <- fbad_request(
        path   = paste0(audience_id),
        method = "DELETE",
        params = list(access_token = fbacc$access_token))

    ## return
    fromJSON(res)

}


#' Share a FB custom audience with other accounts
#' @references \url{https://developers.facebook.com/docs/marketing-api/custom-audience-targeting/v2.3#sharing}
#' @param fbacc FB_Ad_account object returned by \code{fbad_init}
#' @param audience_id audience ID
#' @param adaccounts numeric vector of FB account IDs
#' @note This throws error if you provide wrong account ids OR even valid account ids that were previously granted access to the given custom audience.
#' @export
fbad_share_audience <- function(fbacc, audience_id, adaccounts) {

    fbad_check_fbacc(fbacc)

    flog.info(paste('Sharing', audience_id, 'custom audience ID with', length(adaccounts), 'accounts.'))

    ## make sure adaccounts are integers
    adaccounts <- as.integer64(adaccounts)

    res <- fbad_request(
        path   = paste(audience_id, 'adaccounts', sep = '/'),
        method = "POST",
        params = list(access_token = fbacc$access_token, adaccounts = toJSON(adaccounts)))

}


#' FB add people to audience
#' @references \url{https://developers.facebook.com/docs/marketing-api/custom-audience-targeting/v2.3#create}
#' @param fbacc FB_Ad_account object returned by \code{fbad_init}
#' @param audience_id string
#' @param schema only two schema are supported out of the four: you can add persons to a custom audience by e-mail addresses or phone numbers
#' @param hashes character vector of e-mail addresses or phone numbers to be transformed to hashes
#' @export
fbad_add_audience <- function(fbacc, audience_id,
                              schema = c('EMAIL', 'PHONE'),
                              hashes) {

    fbad_check_fbacc(fbacc)

    flog.info(paste('Adding', length(hashes), schema, 'to', audience_id, 'custom audience ID.'))

    if (length(hashes) == 0) {

        warning('Nothing to send to FB')

    } else {

        ## compute hashes for e-mail or phone numbers
        hashes <- sapply(hashes, digest, serialize = FALSE, algo = 'sha256', USE.NAMES = FALSE)

        ## split hashes into 10K groups
        hashes <- split(hashes, 1:length(hashes) %/% 1e4)

        ## get results
        sapply(hashes, function(hash)
            fbad_request(
                path   = paste(audience_id, 'users', sep = '/'),
                method = "POST",
                params = list(
                    access_token = fbacc$access_token,
                    payload      = toJSON(c(
                        list(schema = unbox(paste0(schema, '_SHA256'))),
                        list(data   = hash))))))

    }

    ## TODO parse results and error handling

}


#' Create a new FB lookalike audience similar to an already existing custom audience
#' @references \url{https://developers.facebook.com/docs/marketing-api/lookalike-audience-targeting/v2.3#create}
#' @param fbacc FB_Ad_account object returned by \code{fbad_init}
#' @param name string
#' @param origin_audience_id numeric ID of origin custom audience
#' @param ratio Between 0.01-0.20 and increments of 0.01. Indicates the top \code{ratio} percent of original audience in the selected country
#' @param country Country name - the country to find the lookalike people.
#' @return lookalike audience ID
#' @export
fbad_create_lookalike_audience <- function(fbacc, name, origin_audience_id, ratio = 0.01, country = 'US') {

    fbad_check_fbacc(fbacc)
    if (missing(name))
        stop('A custom name for the lookalike audience is required.')
    if (missing(origin_audience_id))
        stop('The origin custom audience id is required.')

    flog.info(paste0('Creating new lookalike (', ratio*100, '%%) ', country, ' audience based on ', origin_audience_id, ': ', name))

    ## get results
    res <- fbad_request(
        path   = paste0('act_', fbacc$account_id, '/customaudiences'),
        method = "POST",
        params = list(
            access_token       = fbacc$access_token,
            name               = name,
            origin_audience_id = origin_audience_id,
            lookalike_spec     = toJSON(list(
                ratio   = ratio,
                country = country
                ), auto_unbox = TRUE)))

    ## return ID
    fromJSON(res)$id

}
