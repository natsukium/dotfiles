locals {
  # Notification target only; not a login ID or password reset path, so
  # treated as a semi-public identifier per the repo's secrets convention.
  alert_email = "tomoya.otabi@gmail.com"

  budgets = {
    management = {
      account_id = data.aws_caller_identity.current.account_id
      limit      = "5"
    }
    research = {
      account_id = data.terraform_remote_state.organization.outputs.research_account_id
      limit      = "10"
    }
  }
}

# Per-account monthly cost budgets with email alerts. cost_filter by
# LinkedAccount means each budget tracks spend within a single member
# account, even though all budgets live in the management account where
# consolidated billing aggregates.
resource "aws_budgets_budget" "monthly" {
  for_each = local.budgets

  name         = "${each.key}-monthly"
  budget_type  = "COST"
  limit_amount = each.value.limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filter {
    name   = "LinkedAccount"
    values = [each.value.account_id]
  }

  dynamic "notification" {
    for_each = toset(["50", "80", "100"])
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = tonumber(notification.value)
      threshold_type             = "PERCENTAGE"
      notification_type          = "ACTUAL"
      subscriber_email_addresses = [local.alert_email]
    }
  }

  # Forecasted overrun gives a heads-up before the budget is actually hit.
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [local.alert_email]
  }
}
