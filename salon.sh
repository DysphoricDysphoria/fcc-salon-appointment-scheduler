#! /bin/bash

PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

echo -e "\n~~~~~ MY SALON ~~~~~\n"

REMOVE_LEADING_AND_TRAILING_SPACE() {
  local result="$(echo $1 | sed -r 's/^ *| $//g')" # remove leading and trailing space
  echo $result
}

MAIN_MENU() {
  if [[ $1 ]]; then
    echo -e "\n$1"
  fi

  echo -e "Welcome to My Salon, how can I help you?\n"

  # get available services
  AVAILALE_SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")

  # if no services available
  if [[ -z $AVAILALE_SERVICES ]]; then
    # send to main menu
    MAIN_MENU "Sorry, we don't have any services available right now."
  else
    # display available services
    echo "$AVAILALE_SERVICES" | while read SERVICE_ID BAR NAME; do
      echo "$SERVICE_ID) $NAME"
    done
  fi

  read SERVICE_ID_SELECTED

  # if input is not a number
  if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]; then
    # send to main menu
    MAIN_MENU "That is not a valid service number."
  else
    # get service availability
    SERVICE_SELECTED=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")

    # if not available
    if [[ -z $SERVICE_SELECTED ]]; then
      # send to main menu
      MAIN_MENU "That service is not available."
    else
      # get customer info
      echo -e "\nWhat's your phone number?"
      read CUSTOMER_PHONE

      CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")

      # if customer not found
      if [[ -z $CUSTOMER_NAME ]]; then
        # ask for customer name
        echo -e "\nI don't have a record for that phone number, what's your name?"
        read CUSTOMER_NAME

        # add customer
        CUSTOMER_INSERT_RESULT="$($PSQL "INSERT INTO customers (phone, name) VALUES ('$CUSTOMER_PHONE', '$CUSTOMER_NAME');")"
      fi

      # get customer id
      CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")

      # get appointment time
      echo -e "\nWhat time would you like your $(REMOVE_LEADING_AND_TRAILING_SPACE $SERVICE_SELECTED), $(REMOVE_LEADING_AND_TRAILING_SPACE "$CUSTOMER_NAME")?"
      read SERVICE_TIME

      # add appointment
      APPOINTMENT_INSERT_RESULT="$($PSQL "INSERT INTO appointments (customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME');")"

      # send to main menu
      echo -e "\nI have put you down for a $(REMOVE_LEADING_AND_TRAILING_SPACE $SERVICE_SELECTED) at $SERVICE_TIME, $(REMOVE_LEADING_AND_TRAILING_SPACE "$CUSTOMER_NAME")."
    fi
  fi
}

MAIN_MENU
