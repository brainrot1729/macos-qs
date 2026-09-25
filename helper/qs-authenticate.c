/*
 * qs-authenticate — minimal PAM auth check for macos-qs's lock screen.
 *
 * Usage: qs-authenticate <username>
 * Reads exactly one line (the password) from stdin.
 * Exit code 0 = authenticated, non-zero = anything else.
 *
 * This does the least possible amount of work: it does not open a PAM
 * session, does not touch credentials beyond checking them, and holds
 * the password in memory for as short a time as it can before wiping
 * the buffer. It must be installed setuid-root (pam_unix needs root to
 * read /etc/shadow) — see helper/README.md for exact install steps and
 * why a plain "run this as your own user" install will always fail
 * with PAM_AUTH_ERR even for a correct password.
 */

#include <security/pam_appl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static char g_password[512];

static int conv(int num_msg, const struct pam_message **msg,
                 struct pam_response **resp, void *appdata_ptr) {
    (void)appdata_ptr;

    struct pam_response *responses = calloc((size_t)num_msg, sizeof(struct pam_response));
    if (responses == NULL) {
        return PAM_BUF_ERR;
    }

    for (int i = 0; i < num_msg; i++) {
        responses[i].resp_retcode = 0;
        responses[i].resp = NULL;

        if (msg[i]->msg_style == PAM_PROMPT_ECHO_OFF ||
            msg[i]->msg_style == PAM_PROMPT_ECHO_ON) {
            responses[i].resp = strdup(g_password);
            if (responses[i].resp == NULL) {
                free(responses);
                return PAM_BUF_ERR;
            }
        }
    }

    *resp = responses;
    return PAM_SUCCESS;
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "usage: %s <username>\n", argv[0]);
        return 2;
    }
    const char *username = argv[1];

    if (fgets(g_password, sizeof(g_password), stdin) == NULL) {
        fprintf(stderr, "qs-authenticate: failed to read password from stdin\n");
        return 2;
    }
    g_password[strcspn(g_password, "\n")] = '\0';

    struct pam_conv pamc = { conv, NULL };
    pam_handle_t *pamh = NULL;

    /* "qs-authenticate" is the PAM service name — see the accompanying
     * /etc/pam.d/qs-authenticate, which must exist or every attempt
     * fails closed with PAM_SYSTEM_ERR. */
    int ret = pam_start("qs-authenticate", username, &pamc, &pamh);
    if (ret != PAM_SUCCESS) {
        memset(g_password, 0, sizeof(g_password));
        return 1;
    }

    ret = pam_authenticate(pamh, 0);
    if (ret == PAM_SUCCESS) {
        ret = pam_acct_mgmt(pamh, 0);
    }

    pam_end(pamh, ret);
    memset(g_password, 0, sizeof(g_password));

    return ret == PAM_SUCCESS ? 0 : 1;
}
