import React, { useState } from 'react'
import { Input } from 'antd'

const { TextArea } = Input
export default function HomePage() {
  const [value, setValue] = useState('')
  const [recipients, setRecipients] = useState([
    {
      address: '',
      outputLink: '',
    },
  ])
  const save = () => {
    console.log(value)
  }
  const add = () => {
    recipients.push({
      address: '',
      outputLink: '',
    })
    setRecipients([...recipients])
  }
  const remove = () => {
    recipients.pop()
    setRecipients([...recipients])
  }
  const submit = () => {
    console.log(recipients)
  }
  const changeInput = (event: any, index: number, label: string) => {
    const value = event.target.value
    if (label === 'address') {
      recipients[index].address = value
    } else {
      recipients[index].outputLink = value
    }
    setRecipients([...recipients])
  }
  return (
    <div>
      <div className="flex flex-col items-center">
        <label className="block text-lg font-medium text-gray-700">
          Description
        </label>
        <div className="w-[80%] my-4">
          <TextArea
            rows={4}
            value={value}
            allowClear={true}
            bordered={true}
            onChange={(e) => {
              setValue(e.target.value)
            }}
          />
        </div>
        <div
          className="lg:flex lg:min-w-0 lg:flex-1 lg:justify-end w-[80%] cursor-default"
          onClick={save}
        >
          <span className="inline-block rounded-lg px-3 py-1.5 text-sm font-semibold leading-6 text-gray-900 shadow-sm ring-1 ring-gray-900/10 hover:ring-gray-900/20">
            Save
          </span>
        </div>
      </div>
      <div className="flex flex-col items-center">
        <label className="block text-lg font-medium text-gray-700">
          Recipients
        </label>
        <div className="w-[80%] my-4 py-10">
          {recipients.map((item, index) => {
            return (
              <div className="w-full flex justify-between my-4" key={index}>
                <Input
                  bordered={true}
                  placeholder="Address"
                  className="w-[45%]"
                  value={item.address}
                  onChange={(e) => changeInput(e, index, 'address')}
                />
                <Input
                  bordered={true}
                  placeholder="Output Link"
                  className="w-[45%]"
                  value={item.outputLink}
                  onChange={(e) => changeInput(e, index, 'outputLink')}
                />
              </div>
            )
          })}
        </div>
        <div className="lg:flex lg:min-w-0 lg:flex-1 lg:justify-end w-[80%] cursor-default">
          <div className="flex-1">
            <span
              onClick={add}
              className="mr-10 inline-block rounded-lg px-3 py-1.5 text-sm font-semibold leading-6 text-gray-900 shadow-sm ring-1 ring-gray-900/10 hover:ring-gray-900/20"
            >
              Add
            </span>
            <span
              onClick={remove}
              className="mr-10 inline-block rounded-lg px-3 py-1.5 text-sm font-semibold leading-6 text-gray-900 shadow-sm ring-1 ring-gray-900/10 hover:ring-gray-900/20"
            >
              Romove
            </span>
          </div>

          <span
            onClick={submit}
            className="inline-block rounded-lg px-3 py-1.5 text-sm font-semibold leading-6 text-gray-900 shadow-sm ring-1 ring-gray-900/10 hover:ring-gray-900/20"
          >
            Submit
          </span>
        </div>
      </div>
    </div>
  )
}
